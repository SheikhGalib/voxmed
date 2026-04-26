-- ============================================================
-- Migration 010 - Medical Tests pricing and patient discovery
-- ============================================================
-- Repairs/creates the shared medical_tests table used by voxmedweb
-- and exposes active tests from approved hospitals to the mobile app.

CREATE TABLE IF NOT EXISTS medical_tests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hospital_id uuid NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  category text,
  price numeric(10, 2) NOT NULL DEFAULT 0,
  hospital_profit_percent numeric(5, 2) NOT NULL DEFAULT 90.00,
  admin_profit_percent numeric(5, 2) NOT NULL DEFAULT 10.00,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE medical_tests
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS category text,
  ADD COLUMN IF NOT EXISTS price numeric(10, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hospital_profit_percent numeric(5, 2) NOT NULL DEFAULT 90.00,
  ADD COLUMN IF NOT EXISTS admin_profit_percent numeric(5, 2) NOT NULL DEFAULT 10.00,
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE medical_tests ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_medical_tests_hospital
  ON medical_tests(hospital_id);

CREATE INDEX IF NOT EXISTS idx_medical_tests_active_price
  ON medical_tests(is_active, price);

DROP POLICY IF EXISTS "Public read active tests from approved hospitals" ON medical_tests;
CREATE POLICY "Public read active tests from approved hospitals"
  ON medical_tests
  FOR SELECT
  TO anon, authenticated
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1
      FROM hospitals h
      WHERE h.id = medical_tests.hospital_id
        AND h.status::text = 'approved'
        AND COALESCE(h.is_active, true) = true
    )
  );

DROP POLICY IF EXISTS "Service role full access tests" ON medical_tests;
CREATE POLICY "Service role full access tests"
  ON medical_tests
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_medical_tests_updated_at ON medical_tests;
CREATE TRIGGER set_medical_tests_updated_at
  BEFORE UPDATE ON medical_tests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Force PostgREST/Supabase API to refresh its schema cache so voxmedweb
-- stops seeing "Could not find column ... in the schema cache" after migration.
NOTIFY pgrst, 'reload schema';
