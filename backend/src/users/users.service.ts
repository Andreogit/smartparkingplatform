import * as bcrypt from 'bcrypt';
import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../prisma/prisma.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UserProfileResponseDto } from './dto/user-profile.dto';

const INCORRECT_CURRENT_PASSWORD = 'Current password is incorrect';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async getProfile(userId: string): Promise<UserProfileResponseDto> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, createdAt: true },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const ok = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException(INCORRECT_CURRENT_PASSWORD);
    }

    const rounds = this.config.get<number>('security.passwordBcryptRounds', 12);
    const passwordHash = await bcrypt.hash(dto.newPassword, rounds);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
  }

  async listFavoriteParkingIds(userId: string): Promise<string[]> {
    const rows = await this.prisma.favoriteParking.findMany({
      where: { userId },
      select: { parkingId: true },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => r.parkingId);
  }

  async addFavorite(userId: string, parkingId: string): Promise<void> {
    const parking = await this.prisma.parking.findUnique({ where: { id: parkingId } });
    if (!parking) {
      throw new NotFoundException('Parking not found');
    }

    await this.prisma.favoriteParking.upsert({
      where: {
        userId_parkingId: { userId, parkingId },
      },
      create: { userId, parkingId },
      update: {},
    });
  }

  async removeFavorite(userId: string, parkingId: string): Promise<void> {
    await this.prisma.favoriteParking.deleteMany({
      where: { userId, parkingId },
    });
  }
}
