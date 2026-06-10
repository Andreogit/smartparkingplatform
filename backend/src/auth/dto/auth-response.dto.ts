import { ApiProperty } from '@nestjs/swagger';

export class AuthUserSummaryDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'email' })
  email!: string;
}

export class AuthResponseDto {
  @ApiProperty({ description: 'JWT sent as Bearer token (HTTPS recommended in production)' })
  accessToken!: string;

  @ApiProperty({ description: 'Token lifetime in seconds' })
  expiresIn!: number;

  @ApiProperty({ example: 'Bearer' })
  tokenType!: string;

  @ApiProperty({ type: AuthUserSummaryDto })
  user!: AuthUserSummaryDto;
}
