import { ApiProperty } from '@nestjs/swagger';

export class RoutePointDto {
  @ApiProperty({ example: 49.841439 })
  latitude!: number;

  @ApiProperty({ example: 24.031955 })
  longitude!: number;
}

export class DrivingRouteDto {
  @ApiProperty({ type: [RoutePointDto] })
  points!: RoutePointDto[];

  @ApiProperty({ description: 'Route length in metres', example: 1250 })
  distanceMeters!: number;

  @ApiProperty({ description: 'Estimated driving time in seconds', example: 420 })
  durationSeconds!: number;
}
