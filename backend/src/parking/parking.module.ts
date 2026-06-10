import { Module } from '@nestjs/common';

import { GoogleDirectionsTrafficService } from './google-directions-traffic.service';
import { ParkingController } from './parking.controller';
import { ParkingService } from './parking.service';

@Module({
  controllers: [ParkingController],
  providers: [ParkingService, GoogleDirectionsTrafficService],
  exports: [GoogleDirectionsTrafficService],
})
export class ParkingModule {}
