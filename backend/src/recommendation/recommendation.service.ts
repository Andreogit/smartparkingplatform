import { Injectable, Logger } from '@nestjs/common';
import { TrafficLevel } from '@prisma/client';

import {
  googleTrafficIntensity,
  GoogleDirectionsTrafficService,
  NearbyTrafficSample,
  trafficDelayRatio as computeTrafficDelayRatio,
} from '../parking/google-directions-traffic.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  NearbyRecommendationsQueryDto,
  RankedParkingDto,
  ScoreComponentsDto,
} from './dto/recommendation.dto';
import {
  computeRecommendationScore,
  normalizeDistanceNorm,
  trafficLevelFromEnum,
} from './recommendation-score.util';

/** Distance between two WGS-84 points in kilometres */
export function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

async function mapWithConcurrency<T, R>(
  items: T[],
  concurrency: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let nextIndex = 0;

  async function worker(): Promise<void> {
    while (nextIndex < items.length) {
      const index = nextIndex++;
      results[index] = await fn(items[index]!, index);
    }
  }

  const workers = Math.min(Math.max(concurrency, 1), items.length);
  await Promise.all(Array.from({ length: workers }, () => worker()));
  return results;
}

@Injectable()
export class RecommendationService {
  private readonly logger = new Logger(RecommendationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly directionsTraffic: GoogleDirectionsTrafficService,
  ) {}

  /**
   * Academic heuristic (no ML):
   * score = 0.6 × trafficLevel + 0.4 × distanceNorm
   * — lower scores indicate a better match for the driver.
   *
   * When a Google Directions API key is configured, trafficLevel prefers live
   * duration_in_traffic near each parking; otherwise falls back to the latest
   * TrafficLog row or a neutral default.
   */
  async rankNearby(query: NearbyRecommendationsQueryDto): Promise<RankedParkingDto[]> {
    const radiusKm = query.radiusKm ?? 5;

    const allParkings = await this.prisma.parking.findMany({
      include: {
        trafficLogs: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        },
      },
    });

    if (allParkings.length === 0) {
      return [];
    }

    const candidates = allParkings
      .map((p) => ({
        parking: p,
        distanceKm: haversineKm(
          query.latitude,
          query.longitude,
          Number(p.latitude),
          Number(p.longitude),
        ),
      }))
      .filter((c) => c.distanceKm <= radiusKm);

    if (candidates.length === 0) {
      return [];
    }

    const parkings = candidates.map((c) => c.parking);
    const distancesKm = candidates.map((c) => c.distanceKm);
    const maxDistance = Math.max(...distancesKm, 1e-6);

    const useGoogleTraffic = this.directionsTraffic.hasApiKey();
    let googleSamples: (NearbyTrafficSample | null)[] = [];

    if (useGoogleTraffic) {
      googleSamples = await mapWithConcurrency(parkings, 8, async (p) =>
        this.directionsTraffic.sampleNearbyRoadTraffic(Number(p.latitude), Number(p.longitude)),
      );
      const sampled = googleSamples.filter(Boolean).length;
      this.logger.debug(`Google traffic sampled for ${sampled}/${parkings.length} parkings`);
    }

    const ranked: RankedParkingDto[] = parkings.map((p, index) => {
      const googleSample = googleSamples[index] ?? null;
      let trafficLevel: number;
      let trafficSource: ScoreComponentsDto['trafficSource'];
      let trafficDelayRatio: number | undefined;

      if (googleSample) {
        trafficLevel = googleTrafficIntensity(googleSample);
        trafficSource = 'google';
        trafficDelayRatio = Number(computeTrafficDelayRatio(googleSample).toFixed(3));
      } else {
        const latest = p.trafficLogs[0];
        if (latest) {
          trafficLevel = trafficLevelFromEnum(latest.trafficLevel);
          trafficSource = 'traffic_log';
        } else {
          trafficLevel = trafficLevelFromEnum(TrafficLevel.UNKNOWN);
          trafficSource = 'default';
        }
      }

      const distanceNorm = normalizeDistanceNorm(distancesKm[index]!, maxDistance);

      const score = computeRecommendationScore(trafficLevel, distanceNorm);

      const components: ScoreComponentsDto = {
        trafficLevel,
        trafficSource,
        trafficDelayRatio,
        distance: distanceNorm,
      };

      return {
        parkingId: p.id,
        name: p.name,
        score,
        components,
      };
    });

    ranked.sort((a, b) => a.score - b.score);
    return ranked;
  }

  async saveUserPick(userId: string, parkingId: string, score: number): Promise<void> {
    await this.prisma.recommendation.create({
      data: {
        userId,
        parkingId,
        recommendationScore: score,
      },
    });
  }
}
