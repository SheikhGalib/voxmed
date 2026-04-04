-- ============================================================
-- VoxMed Seed Data
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================
-- 
-- TEST ACCOUNTS:
--   Patient:  patient@voxmed.test  /  Test1234!
--   Doctor:   doctor@voxmed.test   /  Test1234!
--
-- ============================================================

-- 0. Create enums if not already present (safe to re-run)
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('patient', 'doctor');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE appointment_status AS ENUM ('scheduled','confirmed','in_progress','completed','cancelled','no_show','rescheduled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE appointment_type AS ENUM ('in_person','video','follow_up');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE record_type AS ENUM ('prescription','lab_result','radiology','consultation_note','discharge_summary','other');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE prescription_status AS ENUM ('active','completed','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE renewal_status AS ENUM ('pending','approved','rejected','modified');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE adherence_status AS ENUM ('pending','taken','skipped','missed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE consultation_status AS ENUM ('active','closed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM (
    'appointment_reminder','appointment_rescheduled','appointment_cancelled',
    'medication_reminder','renewal_request','renewal_approved','renewal_rejected',
    'new_lab_result','consultation_invite','ai_triage_result',
    'doctor_absence','general'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ============================================================
-- 1. Create test users in auth.users
-- ============================================================

-- Patient user
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  is_super_admin, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated',
  'patient@voxmed.test',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Adrian Marks", "role": "patient"}'::jsonb,
  false, now(), now(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  jsonb_build_object('sub', '11111111-1111-1111-1111-111111111111', 'email', 'patient@voxmed.test', 'email_verified', true, 'phone_verified', false),
  'email',
  '11111111-1111-1111-1111-111111111111',
  now(), now(), now()
) ON CONFLICT ON CONSTRAINT identities_pkey DO NOTHING;

-- Doctor user 1 (Elena Rodriguez)
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  is_super_admin, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '22222222-2222-2222-2222-222222222222',
  'authenticated', 'authenticated',
  'doctor@voxmed.test',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Dr. Elena Rodriguez", "role": "doctor"}'::jsonb,
  false, now(), now(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES (
  '22222222-2222-2222-2222-222222222222',
  '22222222-2222-2222-2222-222222222222',
  jsonb_build_object('sub', '22222222-2222-2222-2222-222222222222', 'email', 'doctor@voxmed.test', 'email_verified', true, 'phone_verified', false),
  'email',
  '22222222-2222-2222-2222-222222222222',
  now(), now(), now()
) ON CONFLICT ON CONSTRAINT identities_pkey DO NOTHING;

-- Doctor user 2 (Sarah Lawrence)
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  is_super_admin, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '33333333-3333-3333-3333-333333333333',
  'authenticated', 'authenticated',
  'sarah@voxmed.test',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Dr. Sarah Lawrence", "role": "doctor"}'::jsonb,
  false, now(), now(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES (
  '33333333-3333-3333-3333-333333333333',
  '33333333-3333-3333-3333-333333333333',
  jsonb_build_object('sub', '33333333-3333-3333-3333-333333333333', 'email', 'sarah@voxmed.test', 'email_verified', true, 'phone_verified', false),
  'email',
  '33333333-3333-3333-3333-333333333333',
  now(), now(), now()
) ON CONFLICT ON CONSTRAINT identities_pkey DO NOTHING;

-- Doctor user 3 (Julian Thorne)
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  is_super_admin, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '44444444-4444-4444-4444-444444444444',
  'authenticated', 'authenticated',
  'julian@voxmed.test',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Dr. Julian Thorne", "role": "doctor"}'::jsonb,
  false, now(), now(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES (
  '44444444-4444-4444-4444-444444444444',
  '44444444-4444-4444-4444-444444444444',
  jsonb_build_object('sub', '44444444-4444-4444-4444-444444444444', 'email', 'julian@voxmed.test', 'email_verified', true, 'phone_verified', false),
  'email',
  '44444444-4444-4444-4444-444444444444',
  now(), now(), now()
) ON CONFLICT ON CONSTRAINT identities_pkey DO NOTHING;

-- Patient 2 (Eleanor Vance - for collaborative hub)
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  is_super_admin, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '55555555-5555-5555-5555-555555555555',
  'authenticated', 'authenticated',
  'eleanor@voxmed.test',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Eleanor Vance", "role": "patient"}'::jsonb,
  false, now(), now(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
) VALUES (
  '55555555-5555-5555-5555-555555555555',
  '55555555-5555-5555-5555-555555555555',
  jsonb_build_object('sub', '55555555-5555-5555-5555-555555555555', 'email', 'eleanor@voxmed.test', 'email_verified', true, 'phone_verified', false),
  'email',
  '55555555-5555-5555-5555-555555555555',
  now(), now(), now()
) ON CONFLICT ON CONSTRAINT identities_pkey DO NOTHING;

-- ============================================================
-- 2. Profiles (auto-created by trigger, but insert manually for safety)
-- ============================================================

INSERT INTO profiles (id, role, full_name, email, phone, date_of_birth, gender, blood_group, address, emergency_contact, created_at, updated_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'patient', 'Adrian Marks', 'patient@voxmed.test', '+1-555-0101', '1990-05-15', 'male', 'O+', '42 Maple Street, Portland, OR', '{"name": "Maria Marks", "phone": "+1-555-0102", "relation": "Spouse"}'::jsonb, now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'doctor', 'Dr. Elena Rodriguez', 'doctor@voxmed.test', '+1-555-0201', '1982-11-23', 'female', 'A+', '100 Medical Pkwy, Portland, OR', null, now(), now()),
  ('33333333-3333-3333-3333-333333333333', 'doctor', 'Dr. Sarah Lawrence', 'sarah@voxmed.test', '+1-555-0301', '1985-03-12', 'female', 'B+', '200 Clinic Rd, Portland, OR', null, now(), now()),
  ('44444444-4444-4444-4444-444444444444', 'doctor', 'Dr. Julian Thorne', 'julian@voxmed.test', '+1-555-0401', '1978-07-08', 'male', 'AB-', '300 Surgery Blvd, Portland, OR', null, now(), now()),
  ('55555555-5555-5555-5555-555555555555', 'patient', 'Eleanor Vance', 'eleanor@voxmed.test', '+1-555-0501', '1975-09-20', 'female', 'A-', '88 Oak Ave, Portland, OR', '{"name": "Rick Vance", "phone": "+1-555-0502", "relation": "Spouse"}'::jsonb, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  date_of_birth = EXCLUDED.date_of_birth,
  gender = EXCLUDED.gender,
  blood_group = EXCLUDED.blood_group,
  address = EXCLUDED.address,
  emergency_contact = EXCLUDED.emergency_contact,
  updated_at = now();


-- ============================================================
-- 3. Hospitals
-- ============================================================

INSERT INTO hospitals (id, name, description, address, city, state, country, zip_code, phone, email, website, services, rating, is_active, created_at, updated_at)
VALUES
  ('aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Saint Jude Medical Center', 'A leading multi-specialty hospital with 24/7 emergency care, advanced surgical suites, and state-of-the-art diagnostic labs.', '1500 Health Blvd', 'Portland', 'OR', 'USA', '97201', '+1-503-555-1000', 'info@saintjude.test', 'https://saintjude.test', ARRAY['Cardiology','Neurology','Radiology','Pathology','Emergency','ICU','Pediatrics'], 4.8, true, now(), now()),
  ('aaaa2222-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Green Valley Clinic', 'A modern outpatient clinic specializing in primary care, dermatology, and family medicine.', '250 Valley Rd', 'Portland', 'OR', 'USA', '97205', '+1-503-555-2000', 'info@greenvalley.test', 'https://greenvalley.test', ARRAY['General Medicine','Dermatology','Family Medicine','Pediatrics'], 4.5, true, now(), now()),
  ('aaaa3333-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Central Medical Pavilion', 'Comprehensive care facility with focus on cardiology, neurology, and surgical excellence.', '800 Central Ave', 'Portland', 'OR', 'USA', '97209', '+1-503-555-3000', 'info@centralmed.test', 'https://centralmed.test', ARRAY['Cardiology','Neurology','Orthopedics','Surgery','Radiology'], 4.6, true, now(), now())
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 4. Doctor profiles
-- ============================================================

INSERT INTO doctors (id, profile_id, hospital_id, specialty, sub_specialty, qualifications, experience_years, bio, consultation_fee, patients_count, reviews_count, rating, is_available, created_at, updated_at)
VALUES
  ('dddd1111-dddd-dddd-dddd-dddddddddddd', '22222222-2222-2222-2222-222222222222', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Cardiology', 'Interventional Cardiology', ARRAY['MBBS','MD','FACC'], 12, 'Senior Cardiologist with 12 years of experience in interventional procedures and heart failure management. Published researcher with a patient-centered approach.', 120.00, 2400, 850, 4.9, true, now(), now()),
  ('dddd2222-dddd-dddd-dddd-dddddddddddd', '33333333-3333-3333-3333-333333333333', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Neurology', 'Clinical Neurophysiology', ARRAY['MBBS','DM Neuro','Fellowship'], 8, 'Neurologist specializing in headache disorders, epilepsy, and neurodegenerative diseases.', 150.00, 1800, 620, 4.7, true, now(), now()),
  ('dddd3333-dddd-dddd-dddd-dddddddddddd', '44444444-4444-4444-4444-444444444444', 'aaaa3333-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Cardiology', 'Electrophysiology', ARRAY['MBBS','MD','DM Cardiology'], 15, 'Expert in cardiac rhythm management, pacemakers, and ablation procedures with over 15 years in clinical practice.', 130.00, 3100, 920, 4.8, true, now(), now())
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 5. Doctor schedules (weekly recurring)
-- ============================================================

-- Elena Rodriguez (dddd1111) - Mon-Fri 09:00-17:00
INSERT INTO doctor_schedules (id, doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active, created_at) VALUES
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 1, '09:00', '13:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 1, '14:00', '17:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 2, '09:00', '13:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 2, '14:00', '17:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 3, '09:00', '13:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 3, '14:00', '17:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 4, '09:00', '13:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 4, '14:00', '17:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 5, '09:00', '13:00', 30, true, now()),
  (gen_random_uuid(), 'dddd1111-dddd-dddd-dddd-dddddddddddd', 5, '14:00', '17:00', 30, true, now())
ON CONFLICT DO NOTHING;

-- Sarah Lawrence (dddd2222) - Mon/Wed/Fri
INSERT INTO doctor_schedules (id, doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active, created_at) VALUES
  (gen_random_uuid(), 'dddd2222-dddd-dddd-dddd-dddddddddddd', 1, '10:00', '14:00', 30, true, now()),
  (gen_random_uuid(), 'dddd2222-dddd-dddd-dddd-dddddddddddd', 3, '10:00', '14:00', 30, true, now()),
  (gen_random_uuid(), 'dddd2222-dddd-dddd-dddd-dddddddddddd', 5, '10:00', '14:00', 30, true, now())
ON CONFLICT DO NOTHING;

-- Julian Thorne (dddd3333) - Tue/Thu/Sat
INSERT INTO doctor_schedules (id, doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active, created_at) VALUES
  (gen_random_uuid(), 'dddd3333-dddd-dddd-dddd-dddddddddddd', 2, '08:00', '12:00', 30, true, now()),
  (gen_random_uuid(), 'dddd3333-dddd-dddd-dddd-dddddddddddd', 4, '08:00', '12:00', 30, true, now()),
  (gen_random_uuid(), 'dddd3333-dddd-dddd-dddd-dddddddddddd', 6, '09:00', '13:00', 30, true, now())
ON CONFLICT DO NOTHING;


-- ============================================================
-- 6. Appointments
-- ============================================================

INSERT INTO appointments (id, patient_id, doctor_id, hospital_id, scheduled_start_at, scheduled_end_at, status, type, reason, notes, created_at, updated_at) VALUES
  -- Upcoming: Adrian with Dr. Elena (tomorrow 09:00)
  ('bbbb1111-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date + interval '1 day' + interval '9 hours')::timestamptz,
   (current_date + interval '1 day' + interval '9 hours 30 minutes')::timestamptz,
   'scheduled', 'in_person', 'Follow-up cardiology consultation', null, now(), now()),

  -- Upcoming: Adrian with Dr. Sarah (3 days from now 10:30)
  ('bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'dddd2222-dddd-dddd-dddd-dddddddddddd', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date + interval '3 days' + interval '10 hours 30 minutes')::timestamptz,
   (current_date + interval '3 days' + interval '11 hours')::timestamptz,
   'confirmed', 'in_person', 'Neurology check-up for persistent headaches', null, now(), now()),

  -- Upcoming: Adrian with Dr. Julian (5 days from now)
  ('bbbb3333-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'dddd3333-dddd-dddd-dddd-dddddddddddd', 'aaaa3333-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date + interval '5 days' + interval '8 hours')::timestamptz,
   (current_date + interval '5 days' + interval '8 hours 30 minutes')::timestamptz,
   'scheduled', 'in_person', 'Routine cardiac check-up', null, now(), now()),

  -- Past: Adrian with Dr. Elena (completed 14 days ago)
  ('bbbb4444-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date - interval '14 days' + interval '9 hours')::timestamptz,
   (current_date - interval '14 days' + interval '9 hours 30 minutes')::timestamptz,
   'completed', 'in_person', 'ECG and blood pressure monitoring', 'Patient vitals stable. BP 118/76. ECG normal sinus rhythm.', now() - interval '14 days', now() - interval '14 days'),

  -- Past completed: Adrian with Dr. Sarah (30 days ago)
  ('bbbb5555-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'dddd2222-dddd-dddd-dddd-dddddddddddd', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date - interval '30 days' + interval '10 hours')::timestamptz,
   (current_date - interval '30 days' + interval '10 hours 30 minutes')::timestamptz,
   'completed', 'in_person', 'Annual physical examination', 'General health assessment completed. All findings normal.', now() - interval '30 days', now() - interval '30 days'),

  -- Eleanor Vance with Dr. Elena (today for doctor's clinical dashboard)
  ('bbbb6666-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date + interval '13 hours')::timestamptz,
   (current_date + interval '13 hours 30 minutes')::timestamptz,
   'scheduled', 'follow_up', 'Blood work analysis - diabetes follow-up', null, now(), now()),

  -- Eleanor Vance with Dr. Elena (tomorrow)
  ('bbbb7777-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   (current_date + interval '1 day' + interval '10 hours 30 minutes')::timestamptz,
   (current_date + interval '1 day' + interval '11 hours 15 minutes')::timestamptz,
   'scheduled', 'in_person', 'Chronic pain management', null, now(), now())
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 7. Medical Records (Health Passport data)
-- ============================================================

INSERT INTO medical_records (id, patient_id, doctor_id, appointment_id, record_type, title, description, data, record_date, created_at, updated_at) VALUES
  ('rrrr1111-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'bbbb4444-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   'consultation_note', 'Cardiology Consultation', 'Routine check-up with Dr. Elena Rodriguez. Blood pressure monitoring and ECG performed. All readings within normal range.',
   '{"blood_pressure": "118/76", "ecg": "Normal sinus rhythm", "heart_rate": 72}'::jsonb,
   current_date - interval '14 days', now() - interval '14 days', now() - interval '14 days'),

  ('rrrr2222-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '11111111-1111-1111-1111-111111111111', null, 'bbbb5555-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   'consultation_note', 'Annual Physical', 'General health assessment and immunization booster (Tdap). All vitals within normal range.',
   '{"weight_kg": 78, "height_cm": 178, "bmi": 24.6, "immunization": "Tdap booster"}'::jsonb,
   current_date - interval '30 days', now() - interval '30 days', now() - interval '30 days'),

  ('rrrr3333-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '11111111-1111-1111-1111-111111111111', null, null,
   'consultation_note', 'Urgent Care Visit', 'Acute respiratory infection. Prescribed course of antibiotics and 3 days rest.',
   '{"diagnosis": "Acute upper respiratory infection", "medication": "Amoxicillin 500mg"}'::jsonb,
   current_date - interval '90 days', now() - interval '90 days', now() - interval '90 days'),

  ('rrrr4444-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', null,
   'lab_result', 'Annual Blood Panel', 'Complete blood count and lipid panel analysis. Results analyzed by VoxMed AI.',
   '{"hemoglobin": 14.2, "wbc": 7200, "platelets": 245000, "total_cholesterol": 185, "ldl": 110, "hdl": 55, "triglycerides": 120}'::jsonb,
   current_date - interval '2 days', now() - interval '2 days', now() - interval '2 days'),

  ('rrrr5555-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '11111111-1111-1111-1111-111111111111', null, null,
   'lab_result', 'Lipid Panel', 'Routine lipid panel for cardiovascular risk assessment.',
   '{"total_cholesterol": 190, "ldl": 115, "hdl": 52, "triglycerides": 130, "vldl": 23}'::jsonb,
   current_date - interval '3 days', now() - interval '3 days', now() - interval '3 days'),

  -- Eleanor Vance records
  ('rrrr6666-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd', null,
   'consultation_note', 'Type 2 Diabetes Management', 'Ongoing management of Type 2 Diabetes Mellitus. HbA1c trending positively.',
   '{"diagnosis": "Type 2 Diabetes Mellitus", "hba1c": 6.8, "fasting_glucose": 118}'::jsonb,
   current_date - interval '7 days', now() - interval '7 days', now() - interval '7 days'),

  ('rrrr7777-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '55555555-5555-5555-5555-555555555555', null, null,
   'lab_result', 'HbA1c Test', 'Latest HbA1c reading for diabetes monitoring.',
   '{"hba1c": 6.8, "crp": 0.9}'::jsonb,
   current_date - interval '5 days', now() - interval '5 days', now() - interval '5 days')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 8. Prescriptions & items
-- ============================================================

INSERT INTO prescriptions (id, patient_id, doctor_id, appointment_id, diagnosis, notes, status, issued_date, valid_until, created_at, updated_at) VALUES
  -- Adrian's active prescriptions
  ('pppp1111-pppp-pppp-pppp-pppppppppppp', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'bbbb4444-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   'Hypertension management', 'Continue current dosage. Monitor blood pressure weekly.',
   'active', current_date - interval '60 days', current_date + interval '120 days', now() - interval '60 days', now()),

  ('pppp2222-pppp-pppp-pppp-pppppppppppp', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', null,
   'Type 2 Diabetes management', 'Titrate if fasting glucose remains above 130.',
   'active', current_date - interval '45 days', current_date + interval '135 days', now() - interval '45 days', now()),

  ('pppp3333-pppp-pppp-pppp-pppppppppppp', '11111111-1111-1111-1111-111111111111', 'dddd3333-dddd-dddd-dddd-dddddddddddd', null,
   'Hyperlipidemia management', 'Statin therapy for cholesterol control.',
   'active', current_date - interval '30 days', current_date + interval '150 days', now() - interval '30 days', now()),

  -- Eleanor's prescription
  ('pppp4444-pppp-pppp-pppp-pppppppppppp', '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd', null,
   'Type 2 Diabetes management', 'Continue metformin. Monitor HbA1c quarterly.',
   'active', current_date - interval '20 days', current_date + interval '160 days', now() - interval '20 days', now())
ON CONFLICT (id) DO NOTHING;

-- Prescription items
INSERT INTO prescription_items (id, prescription_id, medication_name, dosage, frequency, duration_days, instructions, quantity, remaining, created_at) VALUES
  -- Lisinopril for Adrian
  ('iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', 'pppp1111-pppp-pppp-pppp-pppppppppppp', 'Lisinopril', '10mg', '1x daily', 180, 'Take in the morning with water on an empty stomach.', 180, 120, now()),

  -- Metformin for Adrian
  ('iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', 'pppp2222-pppp-pppp-pppp-pppppppppppp', 'Metformin', '500mg', '2x daily', 180, 'Take with meals — morning and evening.', 360, 270, now()),

  -- Atorvastatin for Adrian
  ('iiii3333-iiii-iiii-iiii-iiiiiiiiiiii', 'pppp3333-pppp-pppp-pppp-pppppppppppp', 'Atorvastatin', '20mg', '1x nightly', 180, 'Take at bedtime. Avoid grapefruit.', 180, 150, now()),

  -- Metformin for Eleanor
  ('iiii4444-iiii-iiii-iiii-iiiiiiiiiiii', 'pppp4444-pppp-pppp-pppp-pppppppppppp', 'Metformin', '500mg', '2x daily', 180, 'Take with meals.', 360, 320, now()),
  ('iiii5555-iiii-iiii-iiii-iiiiiiiiiiii', 'pppp4444-pppp-pppp-pppp-pppppppppppp', 'Berberine', '50mg', '1x daily', 90, 'Take with breakfast.', 90, 75, now())
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 9. Prescription Renewals (approval queue)
-- ============================================================

INSERT INTO prescription_renewals (id, prescription_id, patient_id, doctor_id, status, requested_at, doctor_notes) VALUES
  ('rrnn1111-rrnn-rrnn-rrnn-rrnnrrnnrrnn', 'pppp1111-pppp-pppp-pppp-pppppppppppp', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'pending', now() - interval '1 day', null),
  ('rrnn2222-rrnn-rrnn-rrnn-rrnnrrnnrrnn', 'pppp2222-pppp-pppp-pppp-pppppppppppp', '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'pending', now() - interval '12 hours', null),
  ('rrnn3333-rrnn-rrnn-rrnn-rrnnrrnnrrnn', 'pppp4444-pppp-pppp-pppp-pppppppppppp', '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'pending', now() - interval '6 hours', null),
  ('rrnn4444-rrnn-rrnn-rrnn-rrnnrrnnrrnn', 'pppp3333-pppp-pppp-pppp-pppppppppppp', '11111111-1111-1111-1111-111111111111', 'dddd3333-dddd-dddd-dddd-dddddddddddd', 'pending', now() - interval '2 hours', null)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- 10. Adherence Logs
-- ============================================================

INSERT INTO adherence_logs (id, patient_id, prescription_item_id, scheduled_time, response_time, status, voice_transcript, ai_confidence_score, created_at) VALUES
  -- Recent adherence for Lisinopril (past 7 days)
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '1 day' + interval '8 hours', now() - interval '1 day' + interval '8 hours 5 minutes', 'taken', 'I took my Lisinopril.', 0.96, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '2 days' + interval '8 hours', now() - interval '2 days' + interval '8 hours 2 minutes', 'taken', 'Yes, took it.', 0.94, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '3 days' + interval '8 hours', now() - interval '3 days' + interval '8 hours 10 minutes', 'taken', 'Done.', 0.92, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '4 days' + interval '8 hours', null, 'missed', null, null, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '5 days' + interval '8 hours', now() - interval '5 days' + interval '8 hours 3 minutes', 'taken', 'Took my meds.', 0.97, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '6 days' + interval '8 hours', now() - interval '6 days' + interval '8 hours 1 minute', 'taken', 'Yes.', 0.91, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii1111-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '7 days' + interval '8 hours', now() - interval '7 days' + interval '8 hours 7 minutes', 'taken', 'Took it.', 0.95, now()),

  -- Metformin morning
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '1 day' + interval '8 hours', now() - interval '1 day' + interval '8 hours 3 minutes', 'taken', 'Took metformin.', 0.94, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '2 days' + interval '8 hours', now() - interval '2 days' + interval '8 hours 5 minutes', 'taken', 'Done.', 0.93, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '3 days' + interval '8 hours', now() - interval '3 days' + interval '9 hours', 'taken', 'Took it late.', 0.88, now()),

  -- Metformin evening
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '1 day' + interval '19 hours', now() - interval '1 day' + interval '19 hours 2 minutes', 'taken', 'Evening dose taken.', 0.95, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '2 days' + interval '19 hours', null, 'skipped', null, null, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'iiii2222-iiii-iiii-iiii-iiiiiiiiiiii', now() - interval '3 days' + interval '19 hours', now() - interval '3 days' + interval '19 hours 5 minutes', 'taken', 'Yes.', 0.92, now())
ON CONFLICT DO NOTHING;


-- ============================================================
-- 11. Wearable Data (for Health Analytics)
-- ============================================================

INSERT INTO wearable_data (id, patient_id, metric_type, value, recorded_at, source, created_at) VALUES
  -- Heart rate data (recent)
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 72}'::jsonb, now() - interval '1 hour', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 68}'::jsonb, now() - interval '3 hours', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 75}'::jsonb, now() - interval '6 hours', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 62}'::jsonb, now() - interval '12 hours', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 78}'::jsonb, now() - interval '1 day', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 84}'::jsonb, now() - interval '2 days', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'heart_rate', '{"bpm": 70}'::jsonb, now() - interval '3 days', 'oura_ring', now()),

  -- Blood pressure data
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'blood_pressure', '{"systolic": 118, "diastolic": 76}'::jsonb, now() - interval '4 hours', 'manual', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'blood_pressure', '{"systolic": 122, "diastolic": 78}'::jsonb, now() - interval '1 day', 'manual', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'blood_pressure', '{"systolic": 115, "diastolic": 74}'::jsonb, now() - interval '2 days', 'manual', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'blood_pressure', '{"systolic": 120, "diastolic": 80}'::jsonb, now() - interval '3 days', 'manual', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'blood_pressure', '{"systolic": 125, "diastolic": 82}'::jsonb, now() - interval '5 days', 'manual', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'blood_pressure', '{"systolic": 117, "diastolic": 75}'::jsonb, now() - interval '7 days', 'manual', now()),

  -- SpO2 data
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'spo2', '{"percentage": 98.6}'::jsonb, now() - interval '2 hours', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'spo2', '{"percentage": 99.1}'::jsonb, now() - interval '1 day', 'oura_ring', now()),

  -- Sleep data
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'sleep', '{"duration_hours": 7.5, "deep_sleep_hours": 1.8, "rem_hours": 2.1, "score": 84}'::jsonb, now() - interval '8 hours', 'oura_ring', now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'sleep', '{"duration_hours": 6.8, "deep_sleep_hours": 1.5, "rem_hours": 1.9, "score": 76}'::jsonb, now() - interval '1 day' - interval '8 hours', 'oura_ring', now()),

  -- Eleanor's vitals (for collaborative hub)
  (gen_random_uuid(), '55555555-5555-5555-5555-555555555555', 'heart_rate', '{"bpm": 72}'::jsonb, now() - interval '30 minutes', 'apple_watch', now()),
  (gen_random_uuid(), '55555555-5555-5555-5555-555555555555', 'blood_pressure', '{"systolic": 118, "diastolic": 74}'::jsonb, now() - interval '1 hour', 'manual', now()),
  (gen_random_uuid(), '55555555-5555-5555-5555-555555555555', 'spo2', '{"percentage": 98.6}'::jsonb, now() - interval '1 hour', 'apple_watch', now())
ON CONFLICT DO NOTHING;


-- ============================================================
-- 12. AI Conversations (for AI Assistant)
-- ============================================================

INSERT INTO ai_conversations (id, patient_id, title, triage_result, created_at, updated_at) VALUES
  ('aicv1111-aicv-aicv-aicv-aicvaicvaicv', '11111111-1111-1111-1111-111111111111', 'Headache Symptoms',
   '{"specialty": "Neurology", "severity": "low", "suggested_doctors": ["dddd2222-dddd-dddd-dddd-dddddddddddd"]}'::jsonb,
   now() - interval '2 hours', now() - interval '2 hours')
ON CONFLICT (id) DO NOTHING;

INSERT INTO ai_messages (id, conversation_id, role, content, metadata, created_at) VALUES
  (gen_random_uuid(), 'aicv1111-aicv-aicv-aicv-aicvaicvaicv', 'assistant',
   'Hello! I''m your medical assistant. To help you best, could you describe what symptoms you''re experiencing and when they started?',
   null, now() - interval '2 hours'),
  (gen_random_uuid(), 'aicv1111-aicv-aicv-aicv-aicvaicvaicv', 'user',
   'I''ve been having a persistent dull headache for the last two days, mostly around my temples.',
   null, now() - interval '1 hour 58 minutes'),
  (gen_random_uuid(), 'aicv1111-aicv-aicv-aicv-aicvaicvaicv', 'assistant',
   'Tension headache suspected. Headaches around the temples are often related to stress or eye strain. I have a few follow-up questions to rule out other possibilities.',
   '{"follow_ups": ["Blurred vision?", "Nausea / Vomiting?", "Sensitivity to light?", "None of these"], "confidence": 0.82}'::jsonb,
   now() - interval '1 hour 57 minutes')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 13. Consultation Sessions (Collaborative Hub)
-- ============================================================

INSERT INTO consultation_sessions (id, patient_id, created_by, title, status, notes, soap_note, created_at, updated_at) VALUES
  ('csss1111-csss-csss-csss-cssscssscsss', '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd',
   'Eleanor Vance - Diabetes Management',
   'active',
   'Based on the latest lab results, we should consider adjusting the medication protocol. The HbA1c results are trending in a positive direction, though we should monitor the patient closely.',
   '{"subjective": "Patient reports improved energy levels", "objective": "HbA1c 6.8, fasting glucose 118", "assessment": "Type 2 DM - improved control", "plan": "Continue current regimen, recheck in 3 months"}'::jsonb,
   now() - interval '3 days', now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO consultation_members (id, session_id, doctor_id, role, joined_at) VALUES
  (gen_random_uuid(), 'csss1111-csss-csss-csss-cssscssscsss', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'primary', now() - interval '3 days'),
  (gen_random_uuid(), 'csss1111-csss-csss-csss-cssscssscsss', 'dddd3333-dddd-dddd-dddd-dddddddddddd', 'specialist', now() - interval '2 days')
ON CONFLICT DO NOTHING;

INSERT INTO consultation_messages (id, session_id, sender_id, content, created_at) VALUES
  (gen_random_uuid(), 'csss1111-csss-csss-csss-cssscssscsss', '22222222-2222-2222-2222-222222222222',
   'Based on the latest lab results, we should consider adjusting the medication protocol. The HbA1c results are trending in a positive direction, though we should monitor the patient closely.',
   now() - interval '2 days'),
  (gen_random_uuid(), 'csss1111-csss-csss-csss-cssscssscsss', '44444444-4444-4444-4444-444444444444',
   'Agreed. I recommend keeping the current Metformin dosage and adding Berberine as a supplement. We should recheck HbA1c in 3 months.',
   now() - interval '1 day')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 14. Reviews
-- ============================================================

INSERT INTO reviews (id, patient_id, doctor_id, appointment_id, rating, comment, created_at) VALUES
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'dddd1111-dddd-dddd-dddd-dddddddddddd', 'bbbb4444-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 5, 'Dr. Rodriguez is thorough and takes time to explain everything. Highly recommend!', now() - interval '10 days'),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'dddd2222-dddd-dddd-dddd-dddddddddddd', 'bbbb5555-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 4, 'Good experience. Dr. Lawrence was very knowledgeable.', now() - interval '25 days'),
  (gen_random_uuid(), '55555555-5555-5555-5555-555555555555', 'dddd1111-dddd-dddd-dddd-dddddddddddd', null, 5, 'Excellent care for managing my diabetes. Very attentive.', now() - interval '5 days')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 15. Notifications
-- ============================================================

INSERT INTO notifications (id, user_id, type, title, body, data, is_read, created_at) VALUES
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'appointment_reminder', 'Appointment Tomorrow',
   'You have an appointment with Dr. Elena Rodriguez tomorrow at 9:00 AM.',
   '{"route": "/doctor-booking", "entity_id": "bbbb1111-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}'::jsonb, false, now()),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'medication_reminder', 'Medication Reminder',
   'Time to take your Lisinopril 10mg.',
   '{"route": "/prescription-renewals", "entity_id": "pppp1111-pppp-pppp-pppp-pppppppppppp"}'::jsonb, false, now() - interval '2 hours'),
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'new_lab_result', 'New Lab Results',
   'Your Annual Blood Panel results are ready for review.',
   '{"route": "/passport", "entity_id": "rrrr4444-rrrr-rrrr-rrrr-rrrrrrrrrrrr"}'::jsonb, true, now() - interval '2 days'),
  -- Doctor notifications
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'renewal_request', 'New Renewal Request',
   'Adrian Marks has requested a prescription renewal for Lisinopril 10mg.',
   '{"route": "/approval-queue", "entity_id": "rrnn1111-rrnn-rrnn-rrnn-rrnnrrnnrrnn"}'::jsonb, false, now() - interval '1 day'),
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'renewal_request', 'New Renewal Request',
   'Eleanor Vance has requested a prescription renewal for Metformin 500mg.',
   '{"route": "/approval-queue", "entity_id": "rrnn3333-rrnn-rrnn-rrnn-rrnnrrnnrrnn"}'::jsonb, false, now() - interval '6 hours')
ON CONFLICT DO NOTHING;


-- ============================================================
-- Done! You can now log in with:
--   Patient: patient@voxmed.test / Test1234!
--   Doctor:  doctor@voxmed.test  / Test1234!
-- ============================================================
