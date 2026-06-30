CREATE TABLE "email_tokens" (
	"id" serial PRIMARY KEY NOT NULL,
	"email" text NOT NULL,
	"token_hash" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"used_at" timestamp,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "subscription_plans" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"price" numeric(10, 2) DEFAULT '0' NOT NULL,
	"token_limit" integer DEFAULT 0 NOT NULL,
	"task_pricing" jsonb DEFAULT '{"extraction":100,"financial_analysis":500,"sector_analysis":800,"integrated_analysis":1200}'::jsonb NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "uploads" ADD COLUMN "hidden_by_user" boolean DEFAULT false NOT NULL;