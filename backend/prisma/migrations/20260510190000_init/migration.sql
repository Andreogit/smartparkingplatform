-- Baseline schema (simplified bachelor project — fresh database).

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE "TrafficLevel" AS ENUM ('UNKNOWN', 'LIGHT', 'MODERATE', 'HEAVY', 'SEVERE');

CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" VARCHAR(320) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

CREATE INDEX "users_created_at_idx" ON "users"("created_at" DESC);

CREATE TABLE "parkings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "latitude" DECIMAL(10, 8) NOT NULL,
    "longitude" DECIMAL(11, 8) NOT NULL,
    "capacity" INTEGER NOT NULL,
    "current_load" INTEGER NOT NULL,
    "zone" VARCHAR(128) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "parkings_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "parkings_zone_id_idx" ON "parkings"("zone", "id");

CREATE TABLE "traffic_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "parking_id" UUID NOT NULL,
    "traffic_level" "TrafficLevel" NOT NULL DEFAULT 'UNKNOWN',
    "timestamp" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "traffic_logs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "traffic_logs_parking_id_timestamp_idx" ON "traffic_logs"("parking_id", "timestamp" DESC);

CREATE INDEX "traffic_logs_timestamp_idx" ON "traffic_logs"("timestamp" DESC);

CREATE TABLE "recommendations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "parking_id" UUID NOT NULL,
    "recommendation_score" DECIMAL(10, 4) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recommendations_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "recommendations_user_id_created_at_idx" ON "recommendations"("user_id", "created_at" DESC);

CREATE INDEX "recommendations_parking_id_created_at_idx" ON "recommendations"("parking_id", "created_at" DESC);

CREATE INDEX "recommendations_created_at_idx" ON "recommendations"("created_at" DESC);

ALTER TABLE "traffic_logs" ADD CONSTRAINT "traffic_logs_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "parkings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "recommendations" ADD CONSTRAINT "recommendations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "recommendations" ADD CONSTRAINT "recommendations_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "parkings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
