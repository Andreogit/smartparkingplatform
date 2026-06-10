import { Injectable } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { CreateTrafficLogDto, TrafficLogResponseDto } from './dto/traffic.dto';

@Injectable()
export class TrafficService {
  constructor(private readonly prisma: PrismaService) {}

  async logTraffic(dto: CreateTrafficLogDto): Promise<TrafficLogResponseDto> {
    return this.prisma.trafficLog.create({
      data: {
        parkingId: dto.parkingId,
        trafficLevel: dto.trafficLevel,
      },
    });
  }

  async listByParking(parkingId: string): Promise<TrafficLogResponseDto[]> {
    return this.prisma.trafficLog.findMany({
      where: { parkingId },
      orderBy: { timestamp: 'desc' },
      take: 50,
    });
  }
}
