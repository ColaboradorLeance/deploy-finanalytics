ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "last_renewal_at" timestamp;
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "next_renewal_at" timestamp;
