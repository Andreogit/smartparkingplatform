import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';

import { CreateTrafficLogDto, TrafficLogResponseDto } from './dto/traffic.dto';
import { TrafficService } from './traffic.service';

@ApiTags('traffic')
@Controller({ path: 'traffic', version: '1' })
export class TrafficController {
  constructor(private readonly trafficService: TrafficService) {}

  @Post('logs')
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Append traffic observation for a parking area' })
  @ApiCreatedResponse({ type: TrafficLogResponseDto })
  logTraffic(@Body() dto: CreateTrafficLogDto): Promise<TrafficLogResponseDto> {
    return this.trafficService.logTraffic(dto);
  }

  @Get('parkings/:parkingId/logs')
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Recent traffic logs for a parking' })
  @ApiOkResponse({ type: [TrafficLogResponseDto] })
  listByParking(@Param('parkingId') parkingId: string): Promise<TrafficLogResponseDto[]> {
    return this.trafficService.listByParking(parkingId);
  }
}
