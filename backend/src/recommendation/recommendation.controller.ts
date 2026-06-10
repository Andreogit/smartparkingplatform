import { Body, Controller, Get, HttpCode, HttpStatus, Post, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';

import { CurrentUser, RequestUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import {
  NearbyRecommendationsQueryDto,
  RankedParkingDto,
  SaveRecommendationDto,
} from './dto/recommendation.dto';
import { RecommendationService } from './recommendation.service';

@ApiTags('recommendations')
@Controller({ path: 'recommendations', version: '1' })
export class RecommendationController {
  constructor(private readonly recommendationService: RecommendationService) {}

  @Public()
  @Get('nearby')
  @ApiOperation({
    summary: 'Rank parkings near coordinates using the weighted heuristic (no ML)',
    description:
      'score = 0.6·trafficLevel + 0.4·distance — sorted ascending (lower is better). ' +
      'Optional radiusKm (default 5) limits candidates by Haversine distance.',
  })
  @ApiOkResponse({ type: [RankedParkingDto] })
  nearby(@Query() query: NearbyRecommendationsQueryDto): Promise<RankedParkingDto[]> {
    return this.recommendationService.rankNearby(query);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Persist chosen recommendation for the authenticated user' })
  @ApiCreatedResponse({ description: 'Stored' })
  async save(
    @CurrentUser() user: RequestUser,
    @Body() dto: SaveRecommendationDto,
  ): Promise<{ ok: true }> {
    await this.recommendationService.saveUserPick(user.userId, dto.parkingId, dto.score);
    return { ok: true };
  }
}
