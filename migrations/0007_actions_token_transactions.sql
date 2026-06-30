CREATE TABLE IF NOT EXISTS "actions" (
  "id" serial PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "category" varchar(50) NOT NULL UNIQUE,
  "token_cost" integer NOT NULL DEFAULT 0,
  "description" text,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "token_transactions" (
  "id" serial PRIMARY KEY NOT NULL,
  "plan_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "category" varchar(50) NOT NULL,
  "token_cost" integer NOT NULL,
  "reference_type" varchar(50),
  "reference_id" integer,
  "created_at" timestamp DEFAULT now()
);
