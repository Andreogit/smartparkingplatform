import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';

import { CurrentUser, RequestUser } from '../common/decorators/current-user.decorator';
import { ChangePasswordDto } from './dto/change-password.dto';
import { FavoriteParkingIdsDto } from './dto/favorite-parking.dto';
import { UserProfileResponseDto } from './dto/user-profile.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@Controller({ path: 'users', version: '1' })
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Current authenticated user (profile)' })
  @ApiOkResponse({ type: UserProfileResponseDto })
  me(@CurrentUser() user: RequestUser): Promise<UserProfileResponseDto> {
    return this.usersService.getProfile(user.userId);
  }

  @Patch('me/password')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Change password for the current user' })
  @ApiNoContentResponse()
  changePassword(
    @CurrentUser() user: RequestUser,
    @Body() dto: ChangePasswordDto,
  ): Promise<void> {
    return this.usersService.changePassword(user.userId, dto);
  }

  @Get('me/favorites')
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'List favorite parking IDs for the current user' })
  @ApiOkResponse({ type: FavoriteParkingIdsDto })
  listFavorites(@CurrentUser() user: RequestUser): Promise<FavoriteParkingIdsDto> {
    return this.usersService.listFavoriteParkingIds(user.userId).then((parkingIds) => ({
      parkingIds,
    }));
  }

  @Post('me/favorites/:parkingId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Add a parking to favorites' })
  @ApiNoContentResponse()
  addFavorite(
    @CurrentUser() user: RequestUser,
    @Param('parkingId') parkingId: string,
  ): Promise<void> {
    return this.usersService.addFavorite(user.userId, parkingId);
  }

  @Delete('me/favorites/:parkingId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Remove a parking from favorites' })
  @ApiNoContentResponse()
  removeFavorite(
    @CurrentUser() user: RequestUser,
    @Param('parkingId') parkingId: string,
  ): Promise<void> {
    return this.usersService.removeFavorite(user.userId, parkingId);
  }
}
