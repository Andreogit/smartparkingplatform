import { ApiProperty } from '@nestjs/swagger';

export class FavoriteParkingIdsDto {
  @ApiProperty({ type: [String], format: 'uuid' })
  parkingIds!: string[];
}
