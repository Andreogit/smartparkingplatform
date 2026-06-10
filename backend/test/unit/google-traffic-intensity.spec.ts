import {
  googleTrafficIntensity,
  trafficDelayRatio,
} from '../../src/parking/google-directions-traffic.service';

describe('google-traffic helpers', () => {
  it('computes delay ratio from duration_in_traffic', () => {
    const ratio = trafficDelayRatio({ baseSeconds: 100, trafficSeconds: 130 });
    expect(ratio).toBeCloseTo(1.3, 3);
  });

  it('maps low delay to lower traffic intensity', () => {
    const light = googleTrafficIntensity({ baseSeconds: 100, trafficSeconds: 105 });
    const heavy = googleTrafficIntensity({ baseSeconds: 100, trafficSeconds: 200 });
    expect(light).toBeLessThan(heavy);
  });

  it('keeps intensity in 0..1 range', () => {
    const intense = googleTrafficIntensity({ baseSeconds: 60, trafficSeconds: 300 });
    expect(intense).toBeGreaterThanOrEqual(0);
    expect(intense).toBeLessThanOrEqual(1);
  });
});
