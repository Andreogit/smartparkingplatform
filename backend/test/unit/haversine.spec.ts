import { haversineKm } from '../../src/recommendation/recommendation.service';

describe('haversineKm', () => {
  it('returns zero for identical points', () => {
    expect(haversineKm(49.84, 24.03, 49.84, 24.03)).toBe(0);
  });

  it('computes plausible distance in Lviv area', () => {
    // Центр Львова ↔ приблизно 2 км на схід
    const km = haversineKm(49.8397, 23.9947, 49.8397, 24.02);
    expect(km).toBeGreaterThan(1);
    expect(km).toBeLessThan(4);
  });
});
