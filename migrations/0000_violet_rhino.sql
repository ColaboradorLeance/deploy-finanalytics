CREATE TABLE "analysis_comments" (
	"id" serial PRIMARY KEY NOT NULL,
	"company_id" integer NOT NULL,
	"analysis_type" text NOT NULL,
	"analysis_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	"content" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "analysis_results" (
	"id" serial PRIMARY KEY NOT NULL,
	"company_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	"data_hash" text NOT NULL,
	"selected_uploads" jsonb NOT NULL,
	"status" text DEFAULT 'processing' NOT NULL,
	"company_name" text,
	"document_types" jsonb,
	"analysis" jsonb,
	"metadata" jsonb,
	"error" text,
	"created_at" timestamp DEFAULT now(),
	"completed_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "cnae_cvm_mapping" (
	"id" serial PRIMARY KEY NOT NULL,
	"cnae_prefix" text NOT NULL,
	"cvm_sector" text NOT NULL,
	"description" text,
	"auto_mapped" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "cnae_cvm_mapping_detail" (
	"id" serial PRIMARY KEY NOT NULL,
	"cnae_prefix" varchar(10) NOT NULL,
	"cvm_sector" varchar(200) NOT NULL,
	"cvm_subsector" varchar(200),
	"description" text,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "companies" (
	"id" serial PRIMARY KEY NOT NULL,
	"cnpj" varchar(18) NOT NULL,
	"razao_social" text NOT NULL,
	"cnae" text,
	"endereco" text,
	"situacao" text,
	"data_abertura" text,
	"plan_id" integer,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "companies_cnpj_unique" UNIQUE("cnpj")
);
--> statement-breakpoint
CREATE TABLE "company_news_cache" (
	"company_id" integer PRIMARY KEY NOT NULL,
	"items" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"fetched_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "damodaran_benchmarks" (
	"id" serial PRIMARY KEY NOT NULL,
	"setor_damodaran" text NOT NULL,
	"cnae_2dig" text NOT NULL,
	"indicador" text NOT NULL,
	"ano" integer NOT NULL,
	"dataset" text NOT NULL,
	"fonte_label" text,
	"n_empresas" integer DEFAULT 0 NOT NULL,
	"excelente" numeric,
	"bom" numeric,
	"regular" numeric,
	"fraco" numeric,
	"unidade" text DEFAULT '%',
	"invertido" boolean DEFAULT false,
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "extraction_edit_logs" (
	"id" serial PRIMARY KEY NOT NULL,
	"extraction_result_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	"section_index" integer NOT NULL,
	"row_index" integer NOT NULL,
	"col_name" varchar(255) NOT NULL,
	"period" varchar(50) NOT NULL,
	"old_value" numeric,
	"new_value" numeric,
	"section_name" varchar(500),
	"row_label" varchar(500),
	"edited_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "extraction_layouts" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"document_type" text DEFAULT '' NOT NULL,
	"extraction_mode" text DEFAULT 'stacked' NOT NULL,
	"is_default" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "extraction_results" (
	"id" serial PRIMARY KEY NOT NULL,
	"upload_id" integer NOT NULL,
	"company_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	"layout_id" integer,
	"document_type" text NOT NULL,
	"periods_detected" jsonb DEFAULT '[]'::jsonb,
	"sections_data" jsonb DEFAULT '[]'::jsonb,
	"column_headers" jsonb DEFAULT '{}'::jsonb,
	"tier_used" text,
	"confidence" text DEFAULT 'MEDIA',
	"warnings" jsonb DEFAULT '[]'::jsonb,
	"metadata" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "integrated_analyses" (
	"id" serial PRIMARY KEY NOT NULL,
	"company_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	"financial_analysis_id" integer NOT NULL,
	"sector_analysis_id" integer NOT NULL,
	"data_hash" text NOT NULL,
	"company_name" text,
	"status" text DEFAULT 'processing' NOT NULL,
	"result_data" jsonb,
	"metadata" jsonb,
	"error" text,
	"created_at" timestamp DEFAULT now(),
	"completed_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "layout_sections" (
	"id" serial PRIMARY KEY NOT NULL,
	"layout_id" integer NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"order_index" integer DEFAULT 0 NOT NULL,
	"section_type" text,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "layout_topics" (
	"id" serial PRIMARY KEY NOT NULL,
	"layout_id" integer NOT NULL,
	"name" text NOT NULL,
	"data_type" text DEFAULT 'number' NOT NULL,
	"extraction_instruction" text NOT NULL,
	"header_hint" text,
	"order_index" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "news_filter_logs" (
	"id" serial PRIMARY KEY NOT NULL,
	"company_id" integer NOT NULL,
	"fetched_at" timestamp DEFAULT now(),
	"candidates_sent" integer DEFAULT 0 NOT NULL,
	"news_returned" integer DEFAULT 0 NOT NULL,
	"input_tokens" integer DEFAULT 0 NOT NULL,
	"output_tokens" integer DEFAULT 0 NOT NULL,
	"cost_usd" numeric DEFAULT '0' NOT NULL
);
--> statement-breakpoint
CREATE TABLE "plan_members" (
	"id" serial PRIMARY KEY NOT NULL,
	"plan_id" integer NOT NULL,
	"email" text NOT NULL,
	"user_id" integer,
	"role" text DEFAULT 'visualizador' NOT NULL,
	"added_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "plans" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"admin_user_id" integer NOT NULL,
	"access_code" varchar(12) NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "plans_access_code_unique" UNIQUE("access_code")
);
--> statement-breakpoint
CREATE TABLE "section_topics" (
	"id" serial PRIMARY KEY NOT NULL,
	"section_id" integer NOT NULL,
	"name" text NOT NULL,
	"data_type" text DEFAULT 'number' NOT NULL,
	"extraction_instruction" text NOT NULL,
	"header_hint" text,
	"order_index" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "sector_analyses" (
	"id" serial PRIMARY KEY NOT NULL,
	"company_id" integer NOT NULL,
	"user_id" integer NOT NULL,
	"sector" text NOT NULL,
	"indicators_hash" text NOT NULL,
	"financial_analysis_id" integer,
	"company_name" text,
	"company_indicators" jsonb,
	"sector_stats" jsonb,
	"percentiles" jsonb,
	"result_data" jsonb,
	"metadata" jsonb,
	"status" text DEFAULT 'processing' NOT NULL,
	"error" text,
	"created_at" timestamp DEFAULT now(),
	"completed_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "sector_benchmarks" (
	"id" serial PRIMARY KEY NOT NULL,
	"cnae" text NOT NULL,
	"indicator_name" text NOT NULL,
	"excelente" numeric NOT NULL,
	"bom" numeric NOT NULL,
	"regular" numeric NOT NULL,
	"fraco" numeric NOT NULL,
	"source" text DEFAULT 'cvm' NOT NULL,
	"confidence_level" text DEFAULT 'medio' NOT NULL,
	"company_count" integer DEFAULT 0 NOT NULL,
	"platform_company_count" integer DEFAULT 0 NOT NULL,
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "sector_company_indicators" (
	"id" serial PRIMARY KEY NOT NULL,
	"cnpj" varchar(18) NOT NULL,
	"cvm_code" text,
	"cnae" text,
	"company_name" text NOT NULL,
	"cvm_sector" text,
	"reference_period" text NOT NULL,
	"indicators" jsonb NOT NULL,
	"raw_data" jsonb,
	"source" text DEFAULT 'cvm' NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "sector_enrichment_logs" (
	"id" serial PRIMARY KEY NOT NULL,
	"cnae" text NOT NULL,
	"cvm_sector" text,
	"status" text DEFAULT 'running' NOT NULL,
	"companies_found" integer DEFAULT 0,
	"companies_processed" integer DEFAULT 0,
	"errors" jsonb DEFAULT '[]'::jsonb,
	"duration_ms" integer,
	"started_at" timestamp DEFAULT now(),
	"completed_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "uploads" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"company_id" integer NOT NULL,
	"analysis_id" integer,
	"document_type" text NOT NULL,
	"filename" text NOT NULL,
	"original_name" text NOT NULL,
	"file_type" text NOT NULL,
	"file_size" text NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"parsed_data" text,
	"uploaded_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "user_companies" (
	"user_id" integer NOT NULL,
	"company_id" integer NOT NULL,
	"access_level" text DEFAULT 'owner' NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "user_companies_user_id_company_id_pk" PRIMARY KEY("user_id","company_id")
);
--> statement-breakpoint
CREATE TABLE "user_sessions" (
	"sid" varchar PRIMARY KEY NOT NULL,
	"sess" jsonb NOT NULL,
	"expire" timestamp (6) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" serial PRIMARY KEY NOT NULL,
	"cpf" varchar(14),
	"name" text NOT NULL,
	"email" text NOT NULL,
	"password" text NOT NULL,
	"birth_date" date,
	"is_admin" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "users_cpf_unique" UNIQUE("cpf"),
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE UNIQUE INDEX "damodaran_uniq_cnae_ind_ds_ano" ON "damodaran_benchmarks" USING btree ("cnae_2dig","indicador","dataset","ano");