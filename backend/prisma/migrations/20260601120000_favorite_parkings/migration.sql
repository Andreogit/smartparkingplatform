-- CreateTable
CREATE TABLE "favorite_parkings" (
    "user_id" UUID NOT NULL,
    "parking_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorite_parkings_pkey" PRIMARY KEY ("user_id","parking_id")
);

-- CreateIndex
CREATE INDEX "favorite_parkings_user_id_idx" ON "favorite_parkings"("user_id");

-- AddForeignKey
ALTER TABLE "favorite_parkings" ADD CONSTRAINT "favorite_parkings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorite_parkings" ADD CONSTRAINT "favorite_parkings_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "parkings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
