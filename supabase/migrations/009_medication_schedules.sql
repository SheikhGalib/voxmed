-- ============================================================
-- Migration 009 — Medication Scheduling & Notification Support
-- ============================================================
-- Run this in Supabase SQL Editor (cloud dashboard).
-- It is safe to re-run (uses IF NOT EXISTS / DO $$ guards).

-- 1. medication_schedules ─ per-patient reminder config
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medication_schedules (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  prescription_item_id  uuid        REFERENCES prescription_items(id) ON DELETE CASCADE,
  medication_name       text        NOT NULL,
  dosage                text        NOT NULL,
  frequency             text        NOT NULL DEFAULT 'daily',
  -- HH:MM strings, e.g. ["08:00","14:00","20:00"]
  times_of_day          text[]      NOT NULL DEFAULT '{"08:00"}',
  -- null = every day; ISO weekday numbers: 1=Mon … 7=Sun
  days_of_week          int[]       DEFAULT NULL,
  is_active             boolean     NOT NULL DEFAULT true,
  notes                 text,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE medication_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients manage own schedules" ON medication_schedules;
CREATE POLICY "Patients manage own schedules"
  ON medication_schedules
  FOR ALL
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

-- 2. Extend adherence_logs with new columns (idempotent)
-- ──────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'adherence_logs' AND column_name = 'schedule_id'
  ) THEN
    ALTER TABLE adherence_logs
      ADD COLUMN schedule_id uuid REFERENCES medication_schedules(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'adherence_logs' AND column_name = 'prescription_item_id'
  ) THEN
    ALTER TABLE adherence_logs
      ADD COLUMN prescription_item_id uuid REFERENCES prescription_items(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'adherence_logs' AND column_name = 'medication_name'
  ) THEN
    ALTER TABLE adherence_logs ADD COLUMN medication_name text;
  END IF;
END $$;

-- 3. Performance indexes
-- ──────────────────────
CREATE INDEX IF NOT EXISTS idx_med_schedules_patient
  ON medication_schedules(patient_id);

CREATE INDEX IF NOT EXISTS idx_med_schedules_active
  ON medication_schedules(patient_id, is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_adherence_logs_patient_time
  ON adherence_logs(patient_id, scheduled_time DESC);

-- 4. updated_at trigger for medication_schedules
-- ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_medication_schedules_updated_at ON medication_schedules;
CREATE TRIGGER set_medication_schedules_updated_at
  BEFORE UPDATE ON medication_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
