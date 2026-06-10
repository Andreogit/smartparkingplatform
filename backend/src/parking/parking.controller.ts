import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';

import { Public } from '../common/decorators/public.decorator';
import { CreateParkingDto, ParkingResponseDto } from './dto/parking.dto';
import { DrivingRouteDto } from './dto/driving-route.dto';
import { RouteQueryDto } from './dto/route-query.dto';
import { ParkingTrafficEstimateDto } from './dto/traffic-estimate.dto';
import { ParkingService } from './parking.service';

@ApiTags('parking')
@Controller({ path: 'parking', version: '1' })
export class ParkingController {
  constructor(private readonly parkingService: ParkingService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'List parkings (public read for map markers)' })
  @ApiOkResponse({ type: [ParkingResponseDto] })
  list(): Promise<ParkingResponseDto[]> {
    return this.parkingService.list();
  }

  /** Registered before :id so “traffic-estimate” is not parsed as a UUID. */
  @Public()
  @Get(':id/traffic-estimate')
  @ApiOperation({
    summary: 'Nearby Google driving traffic sample',
    description:
      'Calls Google Directions with departure_time=now on a short segment from this parking. ' +
      'Compares duration vs duration_in_traffic.',
  })
  @ApiOkResponse({ type: ParkingTrafficEstimateDto })
  trafficEstimate(@Param('id') id: string): Promise<ParkingTrafficEstimateDto> {
    return this.parkingService.estimateTraffic(id);
  }

  @Public()
  @Get(':id/route')
  @ApiOperation({
    summary: 'Driving route polyline from origin to parking (Google Directions)',
  })
  @ApiOkResponse({ type: DrivingRouteDto })
  drivingRoute(
    @Param('id') id: string,
    @Query() query: RouteQueryDto,
  ): Promise<DrivingRouteDto> {
    return this.parkingService.getDrivingRoute(
      id,
      query.originLatitude,
      query.originLongitude,
    );
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Parking detail' })
  @ApiOkResponse({ type: ParkingResponseDto })
  getById(@Param('id') id: string): Promise<ParkingResponseDto> {
    return this.parkingService.getById(id);
  }

  @Post()
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Create parking (authenticated demo seeding)' })
  @ApiCreatedResponse({ type: ParkingResponseDto })
  create(@Body() dto: CreateParkingDto): Promise<ParkingResponseDto> {
    return this.parkingService.create(dto);
  }
}
