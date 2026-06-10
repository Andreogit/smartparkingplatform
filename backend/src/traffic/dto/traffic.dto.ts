import { ApiProperty } from '@nestjs/swagger';
import { TrafficLevel } from '@prisma/client';
import { IsEnum, IsUUID } from 'class-validator';

export class CreateTrafficLogDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  parkingId!: string;

  @ApiProperty({ enum: TrafficLevel })
  @IsEnum(TrafficLevel)
  trafficLevel!: TrafficLevel;
}

export class TrafficLogResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  parkingId!: string;

  @ApiProperty({ enum: TrafficLevel })
  trafficLevel!: TrafficLevel;

  @ApiProperty()
  timestamp!: Date;
}
