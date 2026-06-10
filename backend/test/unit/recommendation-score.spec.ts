import { TrafficLevel } from '@prisma/client';

import {
  SCORE_DISTANCE_WEIGHT,
  SCORE_TRAFFIC_WEIGHT,
  computeRecommendationScore,
  normalizeDistanceNorm,
  trafficLevelFromEnum,
} from '../../src/recommendation/recommendation-score.util';

describe('recommendation-score.util', () => {
  it('uses expected weights', () => {
    expect(SCORE_TRAFFIC_WEIGHT).toBe(0.6);
    expect(SCORE_DISTANCE_WEIGHT).toBe(0.4);
  });

  it('maps traffic enum to numeric levels', () => {
    expect(trafficLevelFromEnum(TrafficLevel.LIGHT)).toBe(0.2);
    expect(trafficLevelFromEnum(TrafficLevel.SEVERE)).toBe(1);
    expect(trafficLevelFromEnum(TrafficLevel.UNKNOWN)).toBe(0.5);
  });

  it('normalizes distance within candidate set', () => {
    expect(normalizeDistanceNorm(0, 5)).toBe(0);
    expect(normalizeDistanceNorm(2.5, 5)).toBe(0.5);
    expect(normalizeDistanceNorm(5, 5)).toBe(1);
  });

  it('prefers lower traffic when distance is equal', () => {
    const near = computeRecommendationScore(0.2, 0.5);
    const busy = computeRecommendationScore(1, 0.5);
    expect(near).toBeLessThan(busy);
  });

  it('prefers closer parking when traffic is equal', () => {
    const close = computeRecommendationScore(0.5, 0.1);
    const far = computeRecommendationScore(0.5, 0.9);
    expect(close).toBeLessThan(far);
  });

  it('computes combined score with formula 0.6·traffic + 0.4·distance', () => {
    expect(computeRecommendationScore(0.5, 0.25)).toBeCloseTo(0.4, 5);
  });
});
