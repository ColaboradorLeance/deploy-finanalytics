ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "subscription_plan_id" integer;
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "last_renewal_at" timestamp;
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "next_renewal_at" timestamp;
