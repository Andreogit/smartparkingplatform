import { TrafficLevel } from '@prisma/client';

/** Ваги евристики score (без ML). */
export const SCORE_TRAFFIC_WEIGHT = 0.6;
export const SCORE_DISTANCE_WEIGHT = 0.4;

/** Числовий рівень трафіку 0–1 для формули score. */
export function trafficLevelFromEnum(level: TrafficLevel): number {
  switch (level) {
    case TrafficLevel.LIGHT:
      return 0.2;
    case TrafficLevel.MODERATE:
      return 0.5;
    case TrafficLevel.HEAVY:
      return 0.75;
    case TrafficLevel.SEVERE:
      return 1;
    case TrafficLevel.UNKNOWN:
    default:
      return 0.5;
  }
}

/** Нормалізація відстані в межах поточного набору кандидатів (0–1). */
export function normalizeDistanceNorm(distanceKm: number, maxDistanceKm: number): number {
  const max = Math.max(maxDistanceKm, 1e-6);
  return Math.min(Math.max(distanceKm / max, 0), 1);
}

/**
 * Менший score — кращий варіант для поїздки зараз.
 * score = 0,6 × trafficLevel + 0,4 × distanceNorm
 */
export function computeRecommendationScore(trafficLevel: number, distanceNorm: number): number {
  return SCORE_TRAFFIC_WEIGHT * trafficLevel + SCORE_DISTANCE_WEIGHT * distanceNorm;
}
