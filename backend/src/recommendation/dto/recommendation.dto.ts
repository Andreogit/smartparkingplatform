import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsOptional, IsUUID, Max, Min } from 'class-validator';

export class NearbyRecommendationsQueryDto {
  @ApiProperty({ example: 49.84 })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @ApiProperty({ example: 24.03 })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  @ApiPropertyOptional({
    description: 'Only rank parkings within this radius (km) from the query point',
    default: 5,
    example: 5,
  })
  @Type(() => Number)
  @IsNumber()
  @Min(0.5)
  @Max(50)
  @IsOptional()
  radiusKm?: number;
}

export class ScoreComponentsDto {
  @ApiProperty({
    description: 'Normalized traffic intensity (0 = light, 1 = severe)',
    example: 0.5,
  })
  trafficLevel!: number;

  @ApiProperty({
    description: 'How trafficLevel was derived',
    enum: ['google', 'traffic_log', 'default'],
    example: 'google',
  })
  trafficSource!: 'google' | 'traffic_log' | 'default';

  @ApiPropertyOptional({
    description: 'Google duration_in_traffic / duration near the parking (when trafficSource=google)',
    example: 1.12,
  })
  trafficDelayRatio?: number;

  @ApiProperty({
    description: 'Distance to user normalized by max distance in the current candidate set',
    example: 0.2,
  })
  distance!: number;
}

export class RankedParkingDto {
  @ApiProperty()
  parkingId!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({
    description:
      'Combined score: 0.6×trafficLevel + 0.4×distance (lower is better)',
    example: 0.37,
  })
  score!: number;

  @ApiProperty({ type: ScoreComponentsDto })
  components!: ScoreComponentsDto;
}

export class SaveRecommendationDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  parkingId!: string;

  @ApiProperty({
    description: 'Same weighted score returned by /nearby (stored for history)',
    example: 0.37,
  })
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  score!: number;
}
