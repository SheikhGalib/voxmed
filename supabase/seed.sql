-- VoxMed local seed data.
-- Requires migration 009 so medication_schedules and extended adherence_logs exist.
-- The seed targets existing patient profiles and creates 30 days of intake data.

DELETE FROM adherence_logs
WHERE voice_transcript = 'seed:30_day_intake_trend';

DELETE FROM medication_schedules
WHERE notes = 'seed:30_day_intake_trend';

WITH seed_patients AS (
  SELECT
    id AS patient_id,
    row_number() OVER (ORDER BY created_at, id) AS patient_index
  FROM profiles
  WHERE role::text = 'patient'
  ORDER BY created_at, id
  LIMIT 8
),
seed_meds AS (
  SELECT *
  FROM (
    VALUES
      (1, 'Metformin', '500mg', 'twice daily', ARRAY['08:00', '20:00']::text[]),
      (2, 'Amlodipine', '5mg', 'daily', ARRAY['09:00']::text[]),
      (3, 'Vitamin D3', '1000 IU', 'daily', ARRAY['13:00']::text[])
  ) AS m(med_index, medication_name, dosage, frequency, times_of_day)
)
INSERT INTO medication_schedules (
  patient_id,
  medication_name,
  dosage,
  frequency,
  times_of_day,
  days_of_week,
  is_active,
  notes
)
SELECT
  p.patient_id,
  m.medication_name,
  m.dosage,
  m.frequency,
  m.times_of_day,
  NULL,
  TRUE,
  'seed:30_day_intake_trend'
FROM seed_patients p
CROSS JOIN seed_meds m;

WITH seed_schedules AS (
  SELECT
    id AS schedule_id,
    patient_id,
    medication_name,
    row_number() OVER (
      PARTITION BY patient_id
      ORDER BY medication_name
    ) AS med_index,
    times_of_day
  FROM medication_schedules
  WHERE notes = 'seed:30_day_intake_trend'
),
days AS (
  SELECT generate_series(0, 29) AS day_offset
),
dose_rows AS (
  SELECT
    s.schedule_id,
    s.patient_id,
    s.medication_name,
    s.med_index,
    d.day_offset,
    dose.time_of_day,
    dose.dose_index,
    ((current_date - d.day_offset) + dose.time_of_day::time)::timestamptz
      AS scheduled_time
  FROM seed_schedules s
  CROSS JOIN days d
  CROSS JOIN LATERAL unnest(s.times_of_day)
    WITH ORDINALITY AS dose(time_of_day, dose_index)
),
classified AS (
  SELECT
    *,
    CASE
      WHEN (day_offset + med_index + dose_index) % 9 = 0 THEN 'missed'
      WHEN (day_offset + med_index + dose_index) % 13 = 0 THEN 'skipped'
      ELSE 'taken'
    END AS status
  FROM dose_rows
  WHERE scheduled_time <= now()
)
INSERT INTO adherence_logs (
  patient_id,
  schedule_id,
  medication_name,
  scheduled_time,
  response_time,
  status,
  voice_transcript
)
SELECT
  patient_id,
  schedule_id,
  medication_name,
  scheduled_time,
  CASE
    WHEN status = 'missed' THEN NULL
    ELSE scheduled_time + interval '12 minutes'
  END AS response_time,
  status::adherence_status,
  'seed:30_day_intake_trend'
FROM classified;
