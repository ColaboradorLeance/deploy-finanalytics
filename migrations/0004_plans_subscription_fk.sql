DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'plans_subscription_plan_id_fkey'
    AND table_name = 'plans'
  ) THEN
    ALTER TABLE "plans" ADD CONSTRAINT "plans_subscription_plan_id_fkey"
      FOREIGN KEY ("subscription_plan_id") REFERENCES "subscription_plans"("id") ON DELETE SET NULL;
  END IF;
END $$;
