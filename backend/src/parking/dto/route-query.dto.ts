import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, Max, Min } from 'class-validator';

export class RouteQueryDto {
  @ApiProperty({ example: 49.84 })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  originLatitude!: number;

  @ApiProperty({ example: 24.03 })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  originLongitude!: number;
}
