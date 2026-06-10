import {
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import type { Parking } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { CreateParkingDto, ParkingResponseDto } from './dto/parking.dto';
import { DrivingRouteDto } from './dto/driving-route.dto';
import { ParkingTrafficEstimateDto } from './dto/traffic-estimate.dto';
import {
  GoogleDirectionsTrafficService,
  trafficDelayRatio,
} from './google-directions-traffic.service';

@Injectable()
export class ParkingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly directionsTraffic: GoogleDirectionsTrafficService,
  ) {}

  async list(): Promise<ParkingResponseDto[]> {
    const rows = await this.prisma.parking.findMany({ orderBy: { name: 'asc' } });
    return rows.map((p) => this.mapParking(p));
  }

  async getDrivingRoute(
    id: string,
    originLatitude: number,
    originLongitude: number,
  ): Promise<DrivingRouteDto> {
    const row = await this.prisma.parking.findUnique({ where: { id } });
    if (!row) {
      throw new NotFoundException('Parking not found');
    }

    if (!this.directionsTraffic.hasApiKey()) {
      throw new ServiceUnavailableException(
        'Set GOOGLE_DIRECTIONS_API_KEY in backend/.env (Directions API enabled in Google Cloud).',
      );
    }

    const destLat = Number(row.latitude);
    const destLng = Number(row.longitude);
    const route = await this.directionsTraffic.getDrivingRoute(
      originLatitude,
      originLongitude,
      destLat,
      destLng,
    );
    if (!route) {
      throw new ServiceUnavailableException(
        'Google Directions returned no route for these coordinates.',
      );
    }

    return {
      points: route.points,
      distanceMeters: route.distanceMeters,
      durationSeconds: route.durationSeconds,
    };
  }

  async getById(id: string): Promise<ParkingResponseDto> {
    const row = await this.prisma.parking.findUnique({ where: { id } });
    if (!row) {
      throw new NotFoundException('Parking not found');
    }
    return this.mapParking(row);
  }

  async create(dto: CreateParkingDto): Promise<ParkingResponseDto> {
    const row = await this.prisma.parking.create({
      data: {
        name: dto.name,
        latitude: dto.latitude,
        longitude: dto.longitude,
        altitude: dto.altitude ?? 0,
        pay24: dto.pay24,
        easyPay: dto.easyPay,
        capacity: dto.capacity,
        zone: dto.zone,
      },
    });
    return this.mapParking(row);
  }

  /**
   * Uses Google Directions “duration” vs “duration_in_traffic” on a short segment near the lot.
   */
  async estimateTraffic(id: string): Promise<ParkingTrafficEstimateDto> {
    const row = await this.prisma.parking.findUnique({ where: { id } });
    if (!row) {
      throw new NotFoundException('Parking not found');
    }

    if (!this.directionsTraffic.hasApiKey()) {
      throw new ServiceUnavailableException(
        'Set GOOGLE_DIRECTIONS_API_KEY in backend/.env (Directions API enabled in Google Cloud, billing on).',
      );
    }

    const lat = Number(row.latitude);
    const lng = Number(row.longitude);
    const sample = await this.directionsTraffic.sampleNearbyRoadTraffic(lat, lng);
    if (!sample) {
      throw new ServiceUnavailableException(
        'Google Directions returned no usable route/traffic for these coordinates (try another offset or check API quotas).',
      );
    }

    return {
      parkingId: row.id,
      trafficDelayRatio: Number(trafficDelayRatio(sample).toFixed(3)),
      baseDurationSeconds: sample.baseSeconds,
      trafficDurationSeconds: sample.trafficSeconds,
      heuristic:
        'Compares baseline driving duration vs duration_in_traffic on a short segment near the parking.',
    };
  }

  private mapParking(p: Parking): ParkingResponseDto {
    return {
      id: p.id,
      name: p.name,
      latitude: String(p.latitude),
      longitude: String(p.longitude),
      altitude: p.altitude,
      pay24: p.pay24,
      easyPay: p.easyPay,
      capacity: p.capacity,
      zone: p.zone,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    };
  }
}
