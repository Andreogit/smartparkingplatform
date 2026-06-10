-- Normalize capacity and drop unused occupancy column.
UPDATE "parkings" SET "capacity" = 20;

ALTER TABLE "parkings" DROP COLUMN "current_load";

ALTER TABLE "parkings" ALTER COLUMN "capacity" SET DEFAULT 20;
