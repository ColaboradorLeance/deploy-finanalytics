-- Migration 0008: api_keys, margin/pricing/platform settings, sector cache, token packages/purchases, user layout prefs
-- Reconstructed from snapshot 0008 — missing from disk, never committed.

--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "api_keys" (
  "id" serial PRIMARY KEY NOT NULL,
  "user_id" integer NOT NULL,
  "plan_id" integer NOT NULL,
  "key_hash" text NOT NULL,
  "label" text NOT NULL,
  "last_used_at" timestamp,
  "expires_at" timestamp,
  "created_at" timestamp DEFAULT now(),
  CONSTRAINT "api_keys_key_hash_unique" UNIQUE("key_hash")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "margin_change_log" (
  "id" serial PRIMARY KEY NOT NULL,
  "scope" varchar(100) NOT NULL,
  "old_value" numeric(10, 4),
  "new_value" numeric(10, 4),
  "changed_by" integer,
  "changed_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "platform_settings" (
  "key" varchar(100) PRIMARY KEY NOT NULL,
  "value" text NOT NULL,
  "updated_at" timestamp DEFAULT now(),
  "updated_by" integer
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "pricing_settings" (
  "key" varchar(100) PRIMARY KEY NOT NULL,
  "value" text NOT NULL,
  "updated_at" timestamp DEFAULT now(),
  "updated_by" integer
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "sector_intelligence_cache" (
  "cnae_code" text NOT NULL,
  "period" varchar(7) NOT NULL,
  "summary" text NOT NULL,
  "fetched_at" timestamp NOT NULL DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "token_packages" (
  "id" serial PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "token_amount" integer NOT NULL,
  "price" numeric(10, 2) NOT NULL DEFAULT '0',
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "token_purchases" (
  "id" serial PRIMARY KEY NOT NULL,
  "plan_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "package_id" integer NOT NULL,
  "token_amount" integer NOT NULL,
  "expires_at" timestamp NOT NULL,
  "created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "user_layout_preferences" (
  "id" serial PRIMARY KEY NOT NULL,
  "user_id" integer NOT NULL,
  "document_type" text NOT NULL,
  "prefer_system_layout" integer NOT NULL DEFAULT 0,
  "preferred_layout_id" integer,
  "created_at" timestamp DEFAULT now(),
  "updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "user_layout_prefs_user_doctype_idx" ON "user_layout_preferences" ("user_id","document_type");
--> statement-breakpoint
ALTER TABLE "companies" ADD COLUMN IF NOT EXISTS "nome_fantasia" text;
--> statement-breakpoint
ALTER TABLE "companies" ADD COLUMN IF NOT EXISTS "deleted_at" timestamp;
--> statement-breakpoint
ALTER TABLE "news_filter_logs" ADD COLUMN IF NOT EXISTS "session_id" text;
--> statement-breakpoint
ALTER TABLE "news_filter_logs" ADD COLUMN IF NOT EXISTS "query" text;
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "rolled_over_tokens" integer NOT NULL DEFAULT 0;
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "rolled_over_actions" jsonb NOT NULL DEFAULT '{}'::jsonb;
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "is_api_only" boolean NOT NULL DEFAULT false;
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "cnpj" varchar(18);
--> statement-breakpoint
ALTER TABLE "plans" ADD COLUMN IF NOT EXISTS "pending_subscription_plan_id" integer;
--> statement-breakpoint
ALTER TABLE "sector_benchmarks" ADD COLUMN IF NOT EXISTS "reference_year" integer;
--> statement-breakpoint
ALTER TABLE "subscription_plans" ADD COLUMN IF NOT EXISTS "action_limits" jsonb DEFAULT '{}'::jsonb;
--> statement-breakpoint
ALTER TABLE "actions" ADD COLUMN IF NOT EXISTS "margin_percent" numeric(5, 2);
--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'actions_category_unique' AND table_name = 'actions'
  ) THEN
    ALTER TABLE "actions" ADD CONSTRAINT "actions_category_unique" UNIQUE("category");
  END IF;
END $$;
--> statement-breakpoint
ALTER TABLE "token_transactions" ADD COLUMN IF NOT EXISTS "real_tokens" integer;
--> statement-breakpoint
ALTER TABLE "token_transactions" ADD COLUMN IF NOT EXISTS "debited_tokens" integer;
--> statement-breakpoint
ALTER TABLE "token_transactions" ADD COLUMN IF NOT EXISTS "margin_percent" numeric(5, 2);
--> statement-breakpoint
ALTER TABLE "token_transactions" ADD COLUMN IF NOT EXISTS "real_cost_usd" numeric;
--> statement-breakpoint
ALTER TABLE "token_transactions" ADD COLUMN IF NOT EXISTS "real_cost_brl" numeric;
