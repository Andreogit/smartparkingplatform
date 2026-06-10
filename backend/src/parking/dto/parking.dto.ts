import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class CreateParkingDto {
  @ApiProperty({ example: 'Rynok Square West' })
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  name!: string;

  @ApiProperty({ example: 49.841_439 })
  @Type(() => Number)
  @IsNumber()
  latitude!: number;

  @ApiProperty({ example: 24.031_955 })
  @Type(() => Number)
  @IsNumber()
  longitude!: number;

  @ApiProperty({ example: 20 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  capacity!: number;

  @ApiProperty({ example: 'center' })
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  zone!: string;

  @ApiProperty({ example: 0, required: false })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  altitude?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  pay24?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  easyPay?: string;
}

export class ParkingResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  latitude!: string;

  @ApiProperty()
  longitude!: string;

  @ApiProperty()
  capacity!: number;

  @ApiProperty()
  zone!: string;

  @ApiProperty({ required: false })
  altitude?: number;

  @ApiProperty({ required: false, description: 'LeoParking CSV column "24"' })
  pay24?: string | null;

  @ApiProperty({ required: false, description: 'LeoParking CSV column EasyPay' })
  easyPay?: string | null;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;
}
