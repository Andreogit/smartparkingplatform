import { ApiProperty } from '@nestjs/swagger';

export class ParkingTrafficEstimateDto {
  @ApiProperty({ description: 'Parking UUID' })
  parkingId!: string;

  @ApiProperty({ description: 'duration_in_traffic / duration on a short nearby driving segment' })
  trafficDelayRatio!: number;

  @ApiProperty({ description: 'Directions API baseline leg duration (seconds)' })
  baseDurationSeconds!: number;

  @ApiProperty({ description: 'Directions API traffic-aware duration (seconds)' })
  trafficDurationSeconds!: number;

  @ApiProperty({
    description: 'How the traffic sample was obtained',
  })
  heuristic!: string;
}
