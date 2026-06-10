import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Short hop (~few hundred metres) so Directions returns a leg with traffic timing. */
export function offsetDestination(lat: number, lng: number, eastM: number, northM: number): {
  lat: number;
  lng: number;
} {
  const latRad = (lat * Math.PI) / 180;
  const dLat = northM / 111_320;
  const dLng = eastM / (111_320 * Math.cos(latRad));
  return { lat: lat + dLat, lng: lng + dLng };
}

interface DirectionsLeg {
  duration?: { value?: number };
  duration_in_traffic?: { value?: number };
}

interface DirectionsStep {
  polyline?: { points?: string };
}

interface DirectionsLegFull extends DirectionsLeg {
  distance?: { value?: number };
  steps?: DirectionsStep[];
}

interface DirectionsRoute {
  legs?: DirectionsLegFull[];
  overview_polyline?: { points?: string };
}

/** Prefer per-step polylines so the path follows roads; fall back to overview. */
export function extractRoutePoints(route: DirectionsRoute | undefined): RoutePoint[] {
  if (!route) {
    return [];
  }

  const merged: RoutePoint[] = [];
  for (const leg of route.legs ?? []) {
    for (const step of leg.steps ?? []) {
      const encoded = step.polyline?.points;
      if (!encoded) {
        continue;
      }
      for (const pt of decodePolyline(encoded)) {
        const last = merged[merged.length - 1];
        if (
          last == null ||
          last.latitude !== pt.latitude ||
          last.longitude !== pt.longitude
        ) {
          merged.push(pt);
        }
      }
    }
  }

  if (merged.length >= 2) {
    return merged;
  }

  const overview = route.overview_polyline?.points;
  return overview ? decodePolyline(overview) : [];
}

interface DirectionsApiResponse {
  status: string;
  error_message?: string;
  routes?: DirectionsRoute[];
}

export type NearbyTrafficSample = {
  baseSeconds: number;
  trafficSeconds: number;
};

export type RoutePoint = {
  latitude: number;
  longitude: number;
};

export type DrivingRouteResult = {
  points: RoutePoint[];
  distanceMeters: number;
  durationSeconds: number;
};

/** Decodes Google encoded polyline (overview_polyline.points). */
export function decodePolyline(encoded: string): RoutePoint[] {
  const points: RoutePoint[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += deltaLat;

    shift = 0;
    result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += deltaLng;

    points.push({ latitude: lat / 1e5, longitude: lng / 1e5 });
  }

  return points;
}

/**
 * Calls Google Maps Directions API (server key — enable “Directions API” + billing in GCP).
 */
@Injectable()
export class GoogleDirectionsTrafficService {
  private readonly logger = new Logger(GoogleDirectionsTrafficService.name);

  constructor(private readonly config: ConfigService) {}

  hasApiKey(): boolean {
    const key = this.config.get<string>('google.directionsApiKey');
    return typeof key === 'string' && key.trim().length > 0;
  }

  /**
   * Samples traffic on a micro-route starting at the parking coordinates.
   */
  async sampleNearbyRoadTraffic(lat: number, lng: number): Promise<NearbyTrafficSample | null> {
    const key = this.config.get<string>('google.directionsApiKey')?.trim();
    if (!key) {
      return null;
    }

    const dest = offsetDestination(lat, lng, 380, 140);
    const url = new URL('https://maps.googleapis.com/maps/api/directions/json');
    url.searchParams.set('origin', `${lat},${lng}`);
    url.searchParams.set('destination', `${dest.lat},${dest.lng}`);
    url.searchParams.set('departure_time', String(Math.floor(Date.now() / 1000)));
    url.searchParams.set('traffic_model', 'best_guess');
    url.searchParams.set('key', key);

    let data: DirectionsApiResponse;
    try {
      const res = await fetch(url.toString(), { method: 'GET' });
      data = (await res.json()) as DirectionsApiResponse;
    } catch (err) {
      this.logger.warn(`Directions request failed: ${err}`);
      return null;
    }

    if (data.status !== 'OK') {
      this.logger.warn(`Directions status=${data.status} msg=${data.error_message ?? ''}`);
      return null;
    }

    const leg = data.routes?.[0]?.legs?.[0];
    if (!leg) {
      return null;
    }

    const base = leg.duration?.value ?? 0;
    const traffic = leg.duration_in_traffic?.value ?? base;
    if (base <= 0) {
      return null;
    }

    return { baseSeconds: base, trafficSeconds: traffic };
  }

  /** Full driving route from origin to destination for map polyline rendering. */
  async getDrivingRoute(
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
  ): Promise<DrivingRouteResult | null> {
    const key = this.config.get<string>('google.directionsApiKey')?.trim();
    if (!key) {
      return null;
    }

    const url = new URL('https://maps.googleapis.com/maps/api/directions/json');
    url.searchParams.set('origin', `${originLat},${originLng}`);
    url.searchParams.set('destination', `${destLat},${destLng}`);
    url.searchParams.set('mode', 'driving');
    url.searchParams.set('key', key);

    let data: DirectionsApiResponse;
    try {
      const res = await fetch(url.toString(), { method: 'GET' });
      data = (await res.json()) as DirectionsApiResponse;
    } catch (err) {
      this.logger.warn(`Directions route request failed: ${err}`);
      return null;
    }

    if (data.status !== 'OK') {
      this.logger.warn(`Directions route status=${data.status} msg=${data.error_message ?? ''}`);
      return null;
    }

    const route = data.routes?.[0];
    const leg = route?.legs?.[0];
    if (!leg) {
      return null;
    }

    const points = extractRoutePoints(route);
    if (points.length < 2) {
      return null;
    }

    return {
      points,
      distanceMeters: leg.distance?.value ?? 0,
      durationSeconds: leg.duration?.value ?? 0,
    };
  }
}

/** duration_in_traffic / baseline duration on the sampled micro-route. */
export function trafficDelayRatio(sample: NearbyTrafficSample): number {
  return sample.trafficSeconds / Math.max(sample.baseSeconds, 30);
}

/**
 * Maps Google traffic delay → normalized intensity (0.2 light … 1 severe),
 * aligned with TrafficLog enum intensity scale.
 */
export function googleTrafficIntensity(sample: NearbyTrafficSample): number {
  const ratioRaw = trafficDelayRatio(sample);
  const clampedRatio = Math.min(Math.max(ratioRaw, 1), 3);
  return 0.2 + 0.8 * ((clampedRatio - 1) / 2);
}
