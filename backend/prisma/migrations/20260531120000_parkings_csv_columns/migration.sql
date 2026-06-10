-- LeoParking CSV fields (X=longitude, Y=latitude, Z, Name, 24, EasyPay)

ALTER TABLE "parkings" ADD COLUMN IF NOT EXISTS "altitude" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "parkings" ADD COLUMN IF NOT EXISTS "pay_24" TEXT;
ALTER TABLE "parkings" ADD COLUMN IF NOT EXISTS "easy_pay" TEXT;

ALTER TABLE "parkings" ALTER COLUMN "capacity" SET DEFAULT 40;
ALTER TABLE "parkings" ALTER COLUMN "current_load" SET DEFAULT 0;
ALTER TABLE "parkings" ALTER COLUMN "zone" SET DEFAULT 'leopark_lviv';

CREATE INDEX IF NOT EXISTS "parkings_longitude_latitude_idx" ON "parkings"("longitude", "latitude");
