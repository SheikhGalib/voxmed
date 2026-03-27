# VoxMed Connect — Database Schema

> **Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime)  
> **Last Updated:** 2026-03-28

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Auth & Roles](#2-auth--roles)
3. [Table Definitions](#3-table-definitions)
4. [Enums & Constants](#4-enums--constants)
5. [Row Level Security (RLS) Policies](#5-row-level-security-rls-policies)
6. [Storage Buckets](#6-storage-buckets)
7. [Indexes](#7-indexes)
8. [Supabase Setup Instructions](#8-supabase-setup-instructions)

---

## 1. Architecture Overview

```
┌──────────────┐     ┌──────────────────────┐     ┌──────────────────┐
│  Flutter App  │────▶│   Supabase Auth       │────▶│  profiles        │
│  (Patient /   │     │   (JWT + RLS)          │     │  (role-based)    │
│   Doctor)     │     └──────────────────────┘     └──────────────────┘
│               │                                         │
│               │────▶ Supabase PostgreSQL ◀──────────────┘
│               │     ┌──────────────────────────────────────────────┐
│               │     │  hospitals, doctors, doctor_schedules,       │
│               │     │  appointments, medical_records,              │
│               │     │  prescriptions, prescription_items,          │
│               │     │  medications, adherence_logs,                │
│               │     │  ai_conversations, ai_messages,              │
│               │     │  notifications, reviews,                     │
│               │     │  consultation_sessions, consultation_members,│
│               │     │  wearable_data                               │
│               │     └──────────────────────────────────────────────┘
│               │
│               │────▶ Supabase Storage
│               │     ┌──────────────────────────────────┐
│               │     │  avatars/  reports/  prescriptions/ │
│               │     └──────────────────────────────────┘
│               │
│               │────▶ Supabase Edge Functions
│               │     ┌──────────────────────────────────┐
│               │     │  gemini-ocr, gemini-triage,      │
│               │     │  auto-reschedule, soap-notes     │
│               │     └──────────────────────────────────┘
└──────────────┘
```

---

## 2. Auth & Roles

Supabase Auth handles sign-up/sign-in. On registration a trigger inserts a row into `profiles`.

| Role      | Description                                              |
|-----------|----------------------------------------------------------|
| `patient` | End users who book appointments, track health, talk to AI |
| `doctor`  | Clinicians who manage schedules, patients, prescriptions  |

> **Note:** Hospitals are entities, not user roles. Doctors can be affiliated with hospitals or operate independently.

---

## 3. Table Definitions

### 3.1 `profiles`

Extends `auth.users`. Created automatically via trigger on sign-up.

| Column             | Type          | Constraints                              | Description                         |
|--------------------|---------------|------------------------------------------|-------------------------------------|
| `id`               | `uuid`        | PK, FK → `auth.users.id` ON DELETE CASCADE | Supabase user ID                   |
| `role`             | `user_role`   | NOT NULL, DEFAULT `'patient'`            | Enum: `patient`, `doctor`           |
| `full_name`        | `text`        | NOT NULL                                 | Display name                        |
| `email`            | `text`        | UNIQUE, NOT NULL                         | Mirrored from auth                  |
| `phone`            | `text`        |                                          | Contact number                      |
| `date_of_birth`    | `date`        |                                          | Patient DOB                         |
| `gender`           | `text`        |                                          | `male`, `female`, `other`           |
| `blood_group`      | `text`        |                                          | e.g. `A+`, `O-`                     |
| `address`          | `text`        |                                          | Full address                        |
| `avatar_url`       | `text`        |                                          | Path in `avatars` bucket            |
| `emergency_contact`| `jsonb`       |                                          | `{ name, phone, relation }`         |
| `created_at`       | `timestamptz` | DEFAULT `now()`                          |                                     |
| `updated_at`       | `timestamptz` | DEFAULT `now()`                          |                                     |

---

### 3.2 `hospitals`

| Column             | Type          | Constraints                  | Description                          |
|--------------------|---------------|------------------------------|--------------------------------------|
| `id`               | `uuid`        | PK, DEFAULT `gen_random_uuid()` | Hospital ID                        |
| `name`             | `text`        | NOT NULL                     | Hospital name                        |
| `description`      | `text`        |                              | About the hospital                   |
| `address`          | `text`        | NOT NULL                     | Physical address                     |
| `city`             | `text`        | NOT NULL                     |                                      |
| `state`            | `text`        |                              |                                      |
| `country`          | `text`        | NOT NULL                     |                                      |
| `zip_code`         | `text`        |                              |                                      |
| `latitude`         | `float8`      |                              | For map/proximity searches           |
| `longitude`        | `float8`      |                              |                                      |
| `phone`            | `text`        |                              |                                      |
| `email`            | `text`        |                              |                                      |
| `website`          | `text`        |                              |                                      |
| `logo_url`         | `text`        |                              | Path in storage bucket               |
| `cover_image_url`  | `text`        |                              |                                      |
| `operating_hours`  | `jsonb`       |                              | `{ mon: {open, close}, tue: ... }`   |
| `services`         | `text[]`      |                              | e.g. `{Radiology, Pathology, ICU}`   |
| `rating`           | `float4`      | DEFAULT `0`                  | Aggregate rating                     |
| `is_active`        | `boolean`     | DEFAULT `true`               |                                      |
| `created_at`       | `timestamptz` | DEFAULT `now()`              |                                      |
| `updated_at`       | `timestamptz` | DEFAULT `now()`              |                                      |

---

### 3.3 `doctors`

Doctor-specific profile data. A doctor is a user with `role = 'doctor'` in `profiles`. This table extends that profile.

| Column             | Type          | Constraints                                 | Description                             |
|--------------------|---------------|---------------------------------------------|-----------------------------------------|
| `id`               | `uuid`        | PK, DEFAULT `gen_random_uuid()`             |                                         |
| `profile_id`       | `uuid`        | UNIQUE, NOT NULL, FK → `profiles.id`        | Links to the user profile               |
| `hospital_id`      | `uuid`        | FK → `hospitals.id`, NULLABLE               | NULL if independent practitioner        |
| `specialty`        | `text`        | NOT NULL                                    | e.g. `Cardiology`, `Neurology`          |
| `sub_specialty`    | `text`        |                                             |                                         |
| `qualifications`   | `text[]`      |                                             | e.g. `{MBBS, MD, FRCS}`                |
| `experience_years` | `int4`        |                                             | Years of practice                       |
| `bio`              | `text`        |                                             | About the doctor                        |
| `consultation_fee` | `numeric(10,2)` |                                           | Base fee                                |
| `patients_count`   | `int4`        | DEFAULT `0`                                 | Aggregate count                         |
| `reviews_count`    | `int4`        | DEFAULT `0`                                 |                                         |
| `rating`           | `float4`      | DEFAULT `0`                                 | Average rating                          |
| `is_available`     | `boolean`     | DEFAULT `true`                              | Online availability flag                |
| `chamber_address`  | `text`        |                                             | For independent doctors                 |
| `chamber_city`     | `text`        |                                             |                                         |
| `created_at`       | `timestamptz` | DEFAULT `now()`                             |                                         |
| `updated_at`       | `timestamptz` | DEFAULT `now()`                             |                                         |

---

### 3.4 `doctor_schedules`

Weekly recurring schedule slots for a doctor.

| Column        | Type          | Constraints                              | Description                          |
|---------------|---------------|------------------------------------------|--------------------------------------|
| `id`          | `uuid`        | PK, DEFAULT `gen_random_uuid()`          |                                      |
| `doctor_id`   | `uuid`        | NOT NULL, FK → `doctors.id`             |                                      |
| `day_of_week` | `int2`        | NOT NULL, CHECK `0-6`                   | 0=Sunday, 6=Saturday                 |
| `start_time`  | `time`        | NOT NULL                                 | e.g. `09:00`                         |
| `end_time`    | `time`        | NOT NULL                                 | e.g. `17:00`                         |
| `slot_duration_minutes` | `int4` | NOT NULL, DEFAULT `30`              | Duration per appointment slot        |
| `is_active`   | `boolean`     | DEFAULT `true`                           |                                      |
| `created_at`  | `timestamptz` | DEFAULT `now()`                          |                                      |

> **Unique Constraint:** `(doctor_id, day_of_week, start_time)` — prevents duplicate slots.

---

### 3.5 `doctor_absences`

Handles "Emergency Absence" feature. Triggers auto-rescheduling Edge Function.

| Column       | Type          | Constraints                              | Description                       |
|--------------|---------------|------------------------------------------|-----------------------------------|
| `id`         | `uuid`        | PK, DEFAULT `gen_random_uuid()`          |                                   |
| `doctor_id`  | `uuid`        | NOT NULL, FK → `doctors.id`             |                                   |
| `date`       | `date`        | NOT NULL                                 | Date of absence                   |
| `reason`     | `text`        |                                          |                                   |
| `is_emergency` | `boolean`   | DEFAULT `false`                          | If true, triggers auto-reschedule |
| `created_at` | `timestamptz` | DEFAULT `now()`                          |                                   |

---

### 3.6 `appointments`

> **Design Decision:** Uses `timestamptz` for scheduling instead of separate `date`/`time` columns to ensure universal UTC alignment across time zones — critical for telehealth where doctor and patient may be in different regions.

| Column             | Type              | Constraints                                 | Description                                    |
|--------------------|-------------------|---------------------------------------------|------------------------------------------------|
| `id`               | `uuid`            | PK, DEFAULT `gen_random_uuid()`             |                                                |
| `patient_id`       | `uuid`            | NOT NULL, FK → `profiles.id`               | Patient who booked                             |
| `doctor_id`        | `uuid`            | NOT NULL, FK → `doctors.id` ON DELETE SET NULL | Preserved if doctor leaves platform (HIPAA)  |
| `hospital_id`      | `uuid`            | FK → `hospitals.id`, NULLABLE              | NULL if independent chamber                    |
| `scheduled_start_at`| `timestamptz`    | NOT NULL                                    | UTC start time of appointment                  |
| `scheduled_end_at` | `timestamptz`     | NOT NULL                                    | UTC end time of appointment                    |
| `status`           | `appointment_status` | NOT NULL, DEFAULT `'scheduled'`          | Enum (see §4)                                  |
| `type`             | `appointment_type`   | NOT NULL, DEFAULT `'in_person'`          | Enum: `in_person`, `video`, `follow_up`        |
| `reason`           | `text`            |                                             | Brief description of visit reason              |
| `notes`            | `text`            |                                             | Doctor notes after visit                       |
| `rescheduled_from` | `uuid`            | FK → `appointments.id`, NULLABLE           | Link to original if auto-rescheduled           |
| `created_at`       | `timestamptz`     | DEFAULT `now()`                             |                                                |
| `updated_at`       | `timestamptz`     | DEFAULT `now()`                             |                                                |

---

### 3.7 `medical_records`

The Health Passport data — prescriptions, lab results, consultation notes, radiology reports, etc.

| Column           | Type              | Constraints                          | Description                                  |
|------------------|-------------------|--------------------------------------|----------------------------------------------|
| `id`             | `uuid`            | PK, DEFAULT `gen_random_uuid()`      |                                              |
| `patient_id`     | `uuid`            | NOT NULL, FK → `profiles.id`        | Owner of the record                          |
| `doctor_id`      | `uuid`            | FK → `doctors.id`, NULLABLE         | Doctor who created/uploaded it               |
| `appointment_id` | `uuid`            | FK → `appointments.id`, NULLABLE    | Related appointment                          |
| `record_type`    | `record_type`     | NOT NULL                             | Enum (see §4)                                |
| `title`          | `text`            | NOT NULL                             | e.g. "Cardiology Consultation"               |
| `description`    | `text`            |                                      | Summary                                      |
| `data`           | `jsonb`           |                                      | Structured data extracted by OCR / manual entry |
| `file_url`       | `text`            |                                      | Path in `reports` storage bucket             |
| `ocr_extracted`  | `boolean`         | DEFAULT `false`                      | Was this auto-extracted via Gemini OCR?       |
| `record_date`    | `date`            |                                      | When the medical event occurred              |
| `created_at`     | `timestamptz`     | DEFAULT `now()`                      |                                              |
| `updated_at`     | `timestamptz`     | DEFAULT `now()`                      |                                              |

---

### 3.8 `prescriptions`

A prescription issued by a doctor during/after an appointment.

| Column           | Type              | Constraints                            | Description                          |
|------------------|-------------------|----------------------------------------|--------------------------------------|
| `id`             | `uuid`            | PK, DEFAULT `gen_random_uuid()`        |                                      |
| `patient_id`     | `uuid`            | NOT NULL, FK → `profiles.id`          |                                      |
| `doctor_id`      | `uuid`            | NOT NULL, FK → `doctors.id` ON DELETE SET NULL | Preserved if doctor leaves (HIPAA)   |
| `appointment_id` | `uuid`            | FK → `appointments.id`, NULLABLE      |                                      |
| `diagnosis`      | `text`            |                                        | Diagnosis summary                    |
| `notes`          | `text`            |                                        | Doctor notes                         |
| `status`         | `prescription_status` | NOT NULL, DEFAULT `'active'`      | Enum: `active`, `completed`, `cancelled` |
| `issued_date`    | `date`            | NOT NULL, DEFAULT `CURRENT_DATE`       |                                      |
| `valid_until`    | `date`            |                                        | Expiry / renewal date                |
| `created_at`     | `timestamptz`     | DEFAULT `now()`                        |                                      |
| `updated_at`     | `timestamptz`     | DEFAULT `now()`                        |                                      |

---

### 3.9 `prescription_items`

Individual medication entries within a prescription.

| Column            | Type           | Constraints                            | Description                              |
|-------------------|----------------|----------------------------------------|------------------------------------------|
| `id`              | `uuid`         | PK, DEFAULT `gen_random_uuid()`        |                                          |
| `prescription_id` | `uuid`         | NOT NULL, FK → `prescriptions.id`     |                                          |
| `medication_name` | `text`         | NOT NULL                               | Drug name                                |
| `dosage`          | `text`         | NOT NULL                               | e.g. "500mg"                             |
| `frequency`       | `text`         | NOT NULL                               | e.g. "3 times a day"                     |
| `duration_days`   | `int4`         |                                        | Duration in days (e.g. `7`); enables computed expiry via `issued_date + duration_days` |
| `instructions`    | `text`         |                                        | e.g. "Take after meals"                  |
| `quantity`        | `int4`         |                                        | Total pills/units                        |
| `remaining`       | `int4`         |                                        | Triggers renewal when low                |
| `created_at`      | `timestamptz`  | DEFAULT `now()`                        |                                          |

---

### 3.10 `prescription_renewals`

Renewal requests from patients, approval queue for doctors.

| Column            | Type              | Constraints                            | Description                              |
|-------------------|-------------------|----------------------------------------|------------------------------------------|
| `id`              | `uuid`            | PK, DEFAULT `gen_random_uuid()`        |                                          |
| `prescription_id` | `uuid`            | NOT NULL, FK → `prescriptions.id`     |                                          |
| `patient_id`      | `uuid`            | NOT NULL, FK → `profiles.id`          |                                          |
| `doctor_id`       | `uuid`            | NOT NULL, FK → `doctors.id` ON DELETE SET NULL |                                   |
| `status`          | `renewal_status`  | NOT NULL, DEFAULT `'pending'`          | Enum: `pending`, `approved`, `rejected`, `modified` |
| `requested_at`    | `timestamptz`     | DEFAULT `now()`                        |                                          |
| `responded_at`    | `timestamptz`     |                                        |                                          |
| `doctor_notes`    | `text`            |                                        | Reason for rejection/modification        |
| `new_prescription_id` | `uuid`        | FK → `prescriptions.id`, NULLABLE    | If modified, links to new prescription   |

---

### 3.11 `adherence_logs`

Voice-tracked medication compliance entries.

| Column            | Type              | Constraints                          | Description                                   |
|-------------------|-------------------|--------------------------------------|-----------------------------------------------|
| `id`              | `uuid`            | PK, DEFAULT `gen_random_uuid()`      |                                               |
| `patient_id`      | `uuid`            | NOT NULL, FK → `profiles.id`        |                                               |
| `prescription_item_id` | `uuid`       | NOT NULL, FK → `prescription_items.id` |                                            |
| `scheduled_time`  | `timestamptz`     | NOT NULL                             | When the patient was supposed to take the med |
| `response_time`   | `timestamptz`     |                                      | When they responded                           |
| `status`          | `adherence_status`| NOT NULL, DEFAULT `'pending'`        | Enum: `pending`, `taken`, `skipped`, `missed` |
| `voice_transcript`| `text`            |                                      | Transcribed voice response                    |
| `ai_confidence_score`| `float4`       |                                      | NLP confidence (0.0–1.0); flag for human review if < threshold |
| `created_at`      | `timestamptz`     | DEFAULT `now()`                      |                                               |

---

### 3.12 `ai_conversations`

Chat sessions with the AI Triage Assistant.

| Column        | Type          | Constraints                          | Description                    |
|---------------|---------------|--------------------------------------|--------------------------------|
| `id`          | `uuid`        | PK, DEFAULT `gen_random_uuid()`      |                                |
| `patient_id`  | `uuid`        | NOT NULL, FK → `profiles.id`        |                                |
| `title`       | `text`        |                                      | Auto-generated or user-set     |
| `triage_result` | `jsonb`     |                                      | `{ specialty, severity, suggested_doctors[] }` |
| `created_at`  | `timestamptz` | DEFAULT `now()`                      |                                |
| `updated_at`  | `timestamptz` | DEFAULT `now()`                      |                                |

---

### 3.13 `ai_messages`

Individual messages within an AI conversation.

| Column            | Type          | Constraints                               | Description                 |
|-------------------|---------------|-------------------------------------------|-----------------------------|
| `id`              | `uuid`        | PK, DEFAULT `gen_random_uuid()`           |                             |
| `conversation_id` | `uuid`        | NOT NULL, FK → `ai_conversations.id`     |                             |
| `role`            | `text`        | NOT NULL, CHECK `IN ('user','assistant')` |                             |
| `content`         | `text`        | NOT NULL                                  | Message body                |
| `metadata`        | `jsonb`       |                                           | Follow-up suggestions, etc. |
| `created_at`      | `timestamptz` | DEFAULT `now()`                           |                             |

---

### 3.14 `consultation_sessions`

Multi-doctor collaborative care sessions.

| Column            | Type                  | Constraints                          | Description                         |
|-------------------|-----------------------|--------------------------------------|-------------------------------------|
| `id`              | `uuid`                | PK, DEFAULT `gen_random_uuid()`      |                                     |
| `patient_id`      | `uuid`                | NOT NULL, FK → `profiles.id`        | Patient being discussed             |
| `created_by`      | `uuid`                | NOT NULL, FK → `doctors.id`         | Primary doctor who initiated        |
| `title`           | `text`                |                                      | Session title                       |
| `status`          | `consultation_status` | NOT NULL, DEFAULT `'active'`         | Enum: `active`, `closed`            |
| `notes`           | `text`                |                                      | Shared clinical notes               |
| `soap_note`       | `jsonb`               |                                      | `{ subjective, objective, assessment, plan }` |
| `created_at`      | `timestamptz`         | DEFAULT `now()`                      |                                     |
| `updated_at`      | `timestamptz`         | DEFAULT `now()`                      |                                     |

---

### 3.15 `consultation_members`

Doctors participating in a collaborative consultation.

| Column          | Type           | Constraints                                 | Description              |
|-----------------|----------------|---------------------------------------------|--------------------------|
| `id`            | `uuid`         | PK, DEFAULT `gen_random_uuid()`             |                          |
| `session_id`    | `uuid`         | NOT NULL, FK → `consultation_sessions.id`  |                          |
| `doctor_id`     | `uuid`         | NOT NULL, FK → `doctors.id`                |                          |
| `role`          | `text`         | DEFAULT `'specialist'`                      | `primary`, `specialist`  |
| `joined_at`     | `timestamptz`  | DEFAULT `now()`                             |                          |

> **Unique Constraint:** `(session_id, doctor_id)`

---

### 3.16 `consultation_messages`

Real-time chat within collaborative sessions (Supabase Realtime).

| Column        | Type          | Constraints                                | Description            |
|---------------|---------------|--------------------------------------------|------------------------|
| `id`          | `uuid`        | PK, DEFAULT `gen_random_uuid()`            |                        |
| `session_id`  | `uuid`        | NOT NULL, FK → `consultation_sessions.id` |                        |
| `sender_id`   | `uuid`        | NOT NULL, FK → `profiles.id`              | Doctor who sent        |
| `content`     | `text`        | NOT NULL                                   |                        |
| `created_at`  | `timestamptz` | DEFAULT `now()`                            |                        |

---

### 3.17 `notifications`

Push/in-app notifications for both roles.

| Column       | Type          | Constraints                          | Description                                  |
|--------------|---------------|--------------------------------------|----------------------------------------------|
| `id`         | `uuid`        | PK, DEFAULT `gen_random_uuid()`      |                                              |
| `user_id`    | `uuid`        | NOT NULL, FK → `profiles.id`        | Recipient                                    |
| `type`       | `notification_type` | NOT NULL                       | Enum (see §4)                                |
| `title`      | `text`        | NOT NULL                             |                                              |
| `body`       | `text`        |                                      |                                              |
| `data`       | `jsonb`       |                                      | Deep-link payload `{ route, entity_id }`     |
| `is_read`    | `boolean`     | DEFAULT `false`                      |                                              |
| `created_at` | `timestamptz` | DEFAULT `now()`                      |                                              |

---

### 3.18 `reviews`

Patient reviews for doctors.

| Column       | Type          | Constraints                          | Description            |
|--------------|---------------|--------------------------------------|------------------------|
| `id`         | `uuid`        | PK, DEFAULT `gen_random_uuid()`      |                        |
| `patient_id` | `uuid`        | NOT NULL, FK → `profiles.id`        |                        |
| `doctor_id`  | `uuid`        | NOT NULL, FK → `doctors.id`         |                        |
| `appointment_id` | `uuid`    | FK → `appointments.id`, NULLABLE    |                        |
| `rating`     | `int2`        | NOT NULL, CHECK `1-5`                |                        |
| `comment`    | `text`        |                                      |                        |
| `created_at` | `timestamptz` | DEFAULT `now()`                      |                        |

> **Unique Constraint:** `(patient_id, appointment_id)` — one review per appointment.

---

### 3.19 `wearable_data`

Synced biometric data from wearables (Phase 2+).

| Column        | Type          | Constraints                          | Description                           |
|---------------|---------------|--------------------------------------|---------------------------------------|
| `id`          | `uuid`        | PK, DEFAULT `gen_random_uuid()`      |                                       |
| `patient_id`  | `uuid`        | NOT NULL, FK → `profiles.id`        |                                       |
| `metric_type` | `text`        | NOT NULL                             | e.g. `heart_rate`, `blood_pressure`, `sleep`, `spo2` |
| `value`       | `jsonb`       | NOT NULL                             | `{ systolic: 118, diastolic: 74 }` or `{ bpm: 72 }` |
| `recorded_at` | `timestamptz` | NOT NULL                             | Timestamp from the wearable           |
| `source`      | `text`        |                                      | e.g. `oura_ring`, `apple_watch`       |
| `created_at`  | `timestamptz` | DEFAULT `now()`                      |                                       |

---

## 4. Enums & Constants

```sql
-- User roles
CREATE TYPE user_role AS ENUM ('patient', 'doctor');

-- Appointment status
CREATE TYPE appointment_status AS ENUM (
  'scheduled', 'confirmed', 'in_progress', 'completed',
  'cancelled', 'no_show', 'rescheduled'
);

-- Appointment type
CREATE TYPE appointment_type AS ENUM ('in_person', 'video', 'follow_up');

-- Medical record type
CREATE TYPE record_type AS ENUM (
  'prescription', 'lab_result', 'radiology',
  'consultation_note', 'discharge_summary', 'other'
);

-- Prescription status
CREATE TYPE prescription_status AS ENUM ('active', 'completed', 'cancelled');

-- Renewal request status
CREATE TYPE renewal_status AS ENUM ('pending', 'approved', 'rejected', 'modified');

-- Adherence status
CREATE TYPE adherence_status AS ENUM ('pending', 'taken', 'skipped', 'missed');

-- Consultation session status
CREATE TYPE consultation_status AS ENUM ('active', 'closed');

-- Notification type
CREATE TYPE notification_type AS ENUM (
  'appointment_reminder', 'appointment_rescheduled', 'appointment_cancelled',
  'medication_reminder', 'renewal_request', 'renewal_approved', 'renewal_rejected',
  'new_lab_result', 'consultation_invite', 'ai_triage_result',
  'doctor_absence', 'general'
);
```

---

## 5. Row Level Security (RLS) Policies

> **Critical:** Enable RLS on ALL tables. Below are the key policies.

### `profiles`
```sql
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Doctors can view patient profiles they have appointments with
CREATE POLICY "Doctors can view their patients"
  ON profiles FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM doctors d
      JOIN appointments a ON a.doctor_id = d.id
      WHERE d.profile_id = auth.uid() AND a.patient_id = profiles.id
    )
  );

-- Public can read doctor profiles
CREATE POLICY "Public read for doctor profiles" 
  ON profiles FOR SELECT USING (role = 'doctor');
```

### `appointments`
```sql
-- Patients see their own appointments
CREATE POLICY "Patients view own appointments"
  ON appointments FOR SELECT USING (auth.uid() = patient_id);

-- Doctors see their own appointments
CREATE POLICY "Doctors view own appointments"
  ON appointments FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM doctors WHERE profile_id = auth.uid() AND id = appointments.doctor_id
    )
  );

-- Patients can book appointments
CREATE POLICY "Patients insert appointments" ON appointments
  FOR INSERT WITH CHECK (patient_id = auth.uid());

-- Patients can update their own appointments
CREATE POLICY "Patients update own appointments" ON appointments
  FOR UPDATE USING (patient_id = auth.uid());

-- Doctors can update appointments assigned to them
CREATE POLICY "Doctors update own appointments" ON appointments
  FOR UPDATE USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
```

### `medical_records`
```sql
-- Patients see their own records
CREATE POLICY "Patients view own records"
  ON medical_records FOR SELECT USING (auth.uid() = patient_id);

-- Doctors see records of their patients
CREATE POLICY "Doctors view patient records"
  ON medical_records FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM doctors d
      JOIN appointments a ON a.doctor_id = d.id
      WHERE d.profile_id = auth.uid() AND a.patient_id = medical_records.patient_id
    )
  );

-- Patients can upload records
CREATE POLICY "Patients insert own records" ON medical_records
  FOR INSERT WITH CHECK (patient_id = auth.uid());

-- Doctors can add records for their patients
CREATE POLICY "Doctors insert patient records" ON medical_records
  FOR INSERT WITH CHECK (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid()) AND
    EXISTS (SELECT 1 FROM appointments a WHERE a.doctor_id = doctor_id AND a.patient_id = medical_records.patient_id)
  );

-- Doctors can update records they added or for their patients
CREATE POLICY "Doctors update patient records" ON medical_records
  FOR UPDATE USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
```

### `hospitals` & `doctors`
```sql
-- Public read access for search/directory
CREATE POLICY "Public read hospitals"
  ON hospitals FOR SELECT USING (true);

CREATE POLICY "Public read doctors"
  ON doctors FOR SELECT USING (true);
```

### `doctor_schedules`
```sql
-- Patients need to see doctor schedules to book appointments
CREATE POLICY "Public read doctor schedules" ON doctor_schedules
  FOR SELECT USING (true);

-- Doctors manage (insert/update/delete) their own schedule slots
CREATE POLICY "Doctors manage own schedules" ON doctor_schedules
  FOR ALL USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
```

### `doctor_absences`
```sql
-- Internal to doctors (triggers reschedules, no need for patients to view directly)
CREATE POLICY "Doctors manage own absences" ON doctor_absences
  FOR ALL USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
```

### `prescriptions`
```sql
CREATE POLICY "Patients view own prescriptions" ON prescriptions
  FOR SELECT USING (patient_id = auth.uid());

CREATE POLICY "Doctors view prescriptions" ON prescriptions
  FOR SELECT USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid()) OR
    EXISTS (
      SELECT 1 FROM doctors d
      JOIN appointments a ON a.doctor_id = d.id
      WHERE d.profile_id = auth.uid() AND a.patient_id = prescriptions.patient_id
    )
  );

CREATE POLICY "Doctors insert own prescriptions" ON prescriptions
  FOR INSERT WITH CHECK (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Doctors update own prescriptions" ON prescriptions
  FOR UPDATE USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
  
CREATE POLICY "Doctors delete own prescriptions" ON prescriptions
  FOR DELETE USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
```

### `prescription_items`
```sql
CREATE POLICY "Users view prescription items" ON prescription_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM prescriptions p
      WHERE p.id = prescription_items.prescription_id AND (
        p.patient_id = auth.uid() OR
        p.doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid()) OR
        EXISTS (
          SELECT 1 FROM doctors d
          JOIN appointments a ON a.doctor_id = d.id
          WHERE d.profile_id = auth.uid() AND a.patient_id = p.patient_id
        )
      )
    )
  );

CREATE POLICY "Doctors manage prescription items" ON prescription_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM prescriptions p
      WHERE p.id = prescription_items.prescription_id AND 
            p.doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    )
  );
```

### `prescription_renewals`
```sql
CREATE POLICY "Patients view own renewals" ON prescription_renewals
  FOR SELECT USING (patient_id = auth.uid());

CREATE POLICY "Doctors view assigned renewals" ON prescription_renewals
  FOR SELECT USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Patients manage own renewals" ON prescription_renewals
  FOR ALL USING (patient_id = auth.uid()) WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Doctors update renewals" ON prescription_renewals
  FOR UPDATE USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
```

### `adherence_logs`
```sql
CREATE POLICY "Patients view own adherence" ON adherence_logs
  FOR SELECT USING (patient_id = auth.uid());

CREATE POLICY "Doctors view patient adherence" ON adherence_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM doctors d
      JOIN appointments a ON a.doctor_id = d.id
      WHERE d.profile_id = auth.uid() AND a.patient_id = adherence_logs.patient_id
    )
  );

CREATE POLICY "Patients manage own adherence" ON adherence_logs
  FOR ALL USING (patient_id = auth.uid());
```

### `ai_conversations` & `ai_messages`
```sql
CREATE POLICY "Patients manage own ai conversations" ON ai_conversations
  FOR ALL USING (patient_id = auth.uid());

CREATE POLICY "Patients manage own ai messages" ON ai_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM ai_conversations c 
      WHERE c.id = ai_messages.conversation_id AND c.patient_id = auth.uid()
    )
  );
```

### `consultation_sessions` & `consultation_members` & `consultation_messages`
```sql
CREATE POLICY "Doctors view consultation sessions" ON consultation_sessions
  FOR SELECT USING (
    created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid()) OR
    EXISTS (
      SELECT 1 FROM consultation_members m
      JOIN doctors d ON d.id = m.doctor_id
      WHERE m.session_id = consultation_sessions.id AND d.profile_id = auth.uid()
    )
  );

CREATE POLICY "Doctors create consultation sessions" ON consultation_sessions
  FOR INSERT WITH CHECK (
    created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Members update consultation sessions" ON consultation_sessions
  FOR UPDATE USING (
    created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid()) OR
    EXISTS (
      SELECT 1 FROM consultation_members m
      JOIN doctors d ON d.id = m.doctor_id
      WHERE m.session_id = consultation_sessions.id AND d.profile_id = auth.uid()
    )
  );

CREATE POLICY "Doctors view associated members" ON consultation_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM consultation_sessions s
      WHERE s.id = consultation_members.session_id AND s.created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    ) OR
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid()) OR
    EXISTS (
      SELECT 1 FROM consultation_members m
      WHERE m.session_id = consultation_members.session_id AND m.doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    )
  );

CREATE POLICY "Creators manage consultation members" ON consultation_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM consultation_sessions s
      WHERE s.id = consultation_members.session_id AND s.created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    )
  );

CREATE POLICY "Members view consultation messages" ON consultation_messages
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM consultation_sessions s WHERE s.id = consultation_messages.session_id AND s.created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())) OR
    EXISTS (SELECT 1 FROM consultation_members m WHERE m.session_id = consultation_messages.session_id AND m.doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid()))
  );

CREATE POLICY "Members insert consultation messages" ON consultation_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    (
      EXISTS (SELECT 1 FROM consultation_sessions s WHERE s.id = session_id AND s.created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())) OR
      EXISTS (SELECT 1 FROM consultation_members m WHERE m.session_id = session_id AND m.doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid()))
    )
  );
```

### `notifications`
```sql
CREATE POLICY "Users manage own notifications" ON notifications
  FOR ALL USING (user_id = auth.uid());
```

### `reviews`
```sql
CREATE POLICY "Public read reviews" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Patients manage own reviews" ON reviews
  FOR ALL USING (patient_id = auth.uid());
```

### `wearable_data`
```sql
CREATE POLICY "Patients view own wearable data" ON wearable_data
  FOR SELECT USING (patient_id = auth.uid());

CREATE POLICY "Doctors view patient wearable data" ON wearable_data
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM doctors d
      JOIN appointments a ON a.doctor_id = d.id
      WHERE d.profile_id = auth.uid() AND a.patient_id = wearable_data.patient_id
    )
  );

CREATE POLICY "Patients manage own wearable data" ON wearable_data
  FOR ALL USING (patient_id = auth.uid());
```

---

## 6. Storage Buckets

| Bucket           | Access              | Purpose                                            |
|------------------|---------------------|----------------------------------------------------|
| `avatars`        | Public read         | Profile photos for patients and doctors             |
| `reports`        | Authenticated + RLS | Uploaded medical reports, lab results, X-rays       |
| `prescriptions`  | Authenticated + RLS | Scanned prescription images for OCR                 |

### Storage Policies
```sql
-- Users can upload their own avatar
CREATE POLICY "Users upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Users can upload their own reports
CREATE POLICY "Users upload own reports"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'reports' AND auth.uid()::text = (storage.foldername(name))[1]);
```

> **File naming convention:** `{bucket}/{user_id}/{timestamp}_{filename}`

---

## 7. Indexes

```sql
-- Performance-critical indexes
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_start ON appointments(scheduled_start_at);
CREATE INDEX idx_appointments_status ON appointments(status);

CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_medical_records_type ON medical_records(record_type);

CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);

CREATE INDEX idx_adherence_patient ON adherence_logs(patient_id);
CREATE INDEX idx_adherence_scheduled ON adherence_logs(scheduled_time);

CREATE INDEX idx_doctors_specialty ON doctors(specialty);
CREATE INDEX idx_doctors_hospital ON doctors(hospital_id);
CREATE INDEX idx_doctors_rating ON doctors(rating DESC);

CREATE INDEX idx_hospitals_city ON hospitals(city);
CREATE INDEX idx_hospitals_rating ON hospitals(rating DESC);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

CREATE INDEX idx_ai_conversations_patient ON ai_conversations(patient_id);

CREATE INDEX idx_consultation_sessions_patient ON consultation_sessions(patient_id);
CREATE INDEX idx_consultation_members_doctor ON consultation_members(doctor_id);
```

---

## 8. Supabase Setup Instructions

### Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) → **New Project**
2. Name it `voxmed`, choose a region close to your users, set a DB password
3. Save the **Project URL** and **publishable key** (`sb_publishable_...`) — you'll need them in `.env`
   > **Note:** Supabase now recommends the new publishable key (`sb_publishable_...`) over the legacy JWT-based `anon` key. See [API Keys docs](https://supabase.com/docs/guides/api/api-keys). The `supabase_flutter` SDK still uses the `anonKey` parameter name; simply pass the publishable key there.

### Step 2: Run the Schema Migration

Navigate to **SQL Editor** in the Supabase dashboard and run these scripts **in order**:

#### 2a. Create Enums
Copy the entire enum block from [§4 Enums & Constants](#4-enums--constants) and execute.

#### 2b. Create Tables
Run the following SQL (auto-generated from the schema above):

```sql
-- ============================================
-- 1. PROFILES (extends auth.users)
-- ============================================
CREATE TABLE profiles (
  id            uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role          user_role NOT NULL DEFAULT 'patient',
  full_name     text NOT NULL,
  email         text UNIQUE NOT NULL,
  phone         text,
  date_of_birth date,
  gender        text,
  blood_group   text,
  address       text,
  avatar_url    text,
  emergency_contact jsonb,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

-- ============================================
-- 2. HOSPITALS
-- ============================================
CREATE TABLE hospitals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  description     text,
  address         text NOT NULL,
  city            text NOT NULL,
  state           text,
  country         text NOT NULL,
  zip_code        text,
  latitude        float8,
  longitude       float8,
  phone           text,
  email           text,
  website         text,
  logo_url        text,
  cover_image_url text,
  operating_hours jsonb,
  services        text[],
  rating          float4 DEFAULT 0,
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ============================================
-- 3. DOCTORS
-- ============================================
CREATE TABLE doctors (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id       uuid UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  hospital_id      uuid REFERENCES hospitals(id) ON DELETE SET NULL,
  specialty        text NOT NULL,
  sub_specialty    text,
  qualifications   text[],
  experience_years int4,
  bio              text,
  consultation_fee numeric(10,2),
  patients_count   int4 DEFAULT 0,
  reviews_count    int4 DEFAULT 0,
  rating           float4 DEFAULT 0,
  is_available     boolean DEFAULT true,
  chamber_address  text,
  chamber_city     text,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

-- ============================================
-- 4. DOCTOR SCHEDULES
-- ============================================
CREATE TABLE doctor_schedules (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id             uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  day_of_week           int2 NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time            time NOT NULL,
  end_time              time NOT NULL,
  slot_duration_minutes int4 NOT NULL DEFAULT 30,
  is_active             boolean DEFAULT true,
  created_at            timestamptz DEFAULT now(),
  UNIQUE (doctor_id, day_of_week, start_time)
);

-- ============================================
-- 5. DOCTOR ABSENCES
-- ============================================
CREATE TABLE doctor_absences (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id    uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  date         date NOT NULL,
  reason       text,
  is_emergency boolean DEFAULT false,
  created_at   timestamptz DEFAULT now()
);

-- ============================================
-- 6. APPOINTMENTS
-- ============================================
CREATE TABLE appointments (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id          uuid NOT NULL REFERENCES doctors(id) ON DELETE SET NULL,
  hospital_id        uuid REFERENCES hospitals(id) ON DELETE SET NULL,
  scheduled_start_at timestamptz NOT NULL,
  scheduled_end_at   timestamptz NOT NULL,
  status             appointment_status NOT NULL DEFAULT 'scheduled',
  type               appointment_type NOT NULL DEFAULT 'in_person',
  reason             text,
  notes              text,
  rescheduled_from   uuid REFERENCES appointments(id) ON DELETE SET NULL,
  created_at         timestamptz DEFAULT now(),
  updated_at         timestamptz DEFAULT now()
);

-- ============================================
-- 7. MEDICAL RECORDS
-- ============================================
CREATE TABLE medical_records (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id      uuid REFERENCES doctors(id) ON DELETE SET NULL,
  appointment_id uuid REFERENCES appointments(id) ON DELETE SET NULL,
  record_type    record_type NOT NULL,
  title          text NOT NULL,
  description    text,
  data           jsonb,
  file_url       text,
  ocr_extracted  boolean DEFAULT false,
  record_date    date,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

-- ============================================
-- 8. PRESCRIPTIONS
-- ============================================
CREATE TABLE prescriptions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id      uuid NOT NULL REFERENCES doctors(id) ON DELETE SET NULL,
  appointment_id uuid REFERENCES appointments(id) ON DELETE SET NULL,
  diagnosis      text,
  notes          text,
  status         prescription_status NOT NULL DEFAULT 'active',
  issued_date    date NOT NULL DEFAULT CURRENT_DATE,
  valid_until    date,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

-- ============================================
-- 9. PRESCRIPTION ITEMS
-- ============================================
CREATE TABLE prescription_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id  uuid NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  medication_name  text NOT NULL,
  dosage           text NOT NULL,
  frequency        text NOT NULL,
  duration_days    int4,
  instructions     text,
  quantity         int4,
  remaining        int4,
  created_at       timestamptz DEFAULT now()
);

-- ============================================
-- 10. PRESCRIPTION RENEWALS
-- ============================================
CREATE TABLE prescription_renewals (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id       uuid NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  patient_id            uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id             uuid NOT NULL REFERENCES doctors(id) ON DELETE SET NULL,
  status                renewal_status NOT NULL DEFAULT 'pending',
  requested_at          timestamptz DEFAULT now(),
  responded_at          timestamptz,
  doctor_notes          text,
  new_prescription_id   uuid REFERENCES prescriptions(id) ON DELETE SET NULL
);

-- ============================================
-- 11. ADHERENCE LOGS
-- ============================================
CREATE TABLE adherence_logs (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  prescription_item_id  uuid NOT NULL REFERENCES prescription_items(id) ON DELETE CASCADE,
  scheduled_time        timestamptz NOT NULL,
  response_time         timestamptz,
  status                adherence_status NOT NULL DEFAULT 'pending',
  voice_transcript      text,
  ai_confidence_score   float4,
  created_at            timestamptz DEFAULT now()
);

-- ============================================
-- 12. AI CONVERSATIONS
-- ============================================
CREATE TABLE ai_conversations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         text,
  triage_result jsonb,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

-- ============================================
-- 13. AI MESSAGES
-- ============================================
CREATE TABLE ai_messages (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  uuid NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
  role             text NOT NULL CHECK (role IN ('user', 'assistant')),
  content          text NOT NULL,
  metadata         jsonb,
  created_at       timestamptz DEFAULT now()
);

-- ============================================
-- 14. CONSULTATION SESSIONS
-- ============================================
CREATE TABLE consultation_sessions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_by  uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  title       text,
  status      consultation_status NOT NULL DEFAULT 'active',
  notes       text,
  soap_note   jsonb,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- ============================================
-- 15. CONSULTATION MEMBERS
-- ============================================
CREATE TABLE consultation_members (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES consultation_sessions(id) ON DELETE CASCADE,
  doctor_id  uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  role       text DEFAULT 'specialist',
  joined_at  timestamptz DEFAULT now(),
  UNIQUE (session_id, doctor_id)
);

-- ============================================
-- 16. CONSULTATION MESSAGES
-- ============================================
CREATE TABLE consultation_messages (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES consultation_sessions(id) ON DELETE CASCADE,
  sender_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content    text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 17. NOTIFICATIONS
-- ============================================
CREATE TABLE notifications (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type       notification_type NOT NULL,
  title      text NOT NULL,
  body       text,
  data       jsonb,
  is_read    boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 18. REVIEWS
-- ============================================
CREATE TABLE reviews (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id      uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  appointment_id uuid REFERENCES appointments(id) ON DELETE SET NULL,
  rating         int2 NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment        text,
  created_at     timestamptz DEFAULT now(),
  UNIQUE (patient_id, appointment_id)
);

-- ============================================
-- 19. WEARABLE DATA (Phase 2+)
-- ============================================
CREATE TABLE wearable_data (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  metric_type text NOT NULL,
  value       jsonb NOT NULL,
  recorded_at timestamptz NOT NULL,
  source      text,
  created_at  timestamptz DEFAULT now()
);
```

#### 2c. Create Indexes
Copy the index block from [§7 Indexes](#7-indexes) and execute.

#### 2d. Enable RLS
```sql
-- Enable RLS on ALL tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_absences ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_renewals ENABLE ROW LEVEL SECURITY;
ALTER TABLE adherence_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE wearable_data ENABLE ROW LEVEL SECURITY;
```

Then apply the RLS policies from [§5](#5-row-level-security-rls-policies).

#### 2e. Create the Auto-Profile Trigger

```sql
-- Automatically create a profile row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'patient')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

#### 2f. Create the `updated_at` Trigger

```sql
-- Auto-update updated_at on any row modification
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER set_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON hospitals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON doctors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON medical_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON prescriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON ai_conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON consultation_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Step 3: Create Storage Buckets

In the Supabase dashboard → **Storage**:

1. Create bucket `avatars` → Set as **Public**
2. Create bucket `reports` → Set as **Private**
3. Create bucket `prescriptions` → Set as **Private**

Apply the storage policies from [§6](#6-storage-buckets).

### Step 4: Configure Auth

1. Go to **Authentication** → **Providers** → Enable **Email** sign-up
2. Optionally enable **Google OAuth** (use the client secret in `docs/`)
3. In **Auth Settings**, ensure "Confirm email" is set to your preference

### Step 5: Set Environment Variables

Update `.env` in project root:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxx   # Replaces the legacy anon key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # For Edge Functions only — NEVER expose publicly
GEMINI_API_KEY=your-gemini-api-key
```

> **Important:** The `SUPABASE_PUBLISHABLE_KEY` uses Supabase's new key format (`sb_publishable_...`). In `main.dart`, pass this value into the `anonKey` parameter of `Supabase.initialize()` — the SDK parameter name hasn't changed, but the key type has. See [Supabase API Keys](https://supabase.com/docs/guides/api/api-keys) for details.

### Step 6: Install Flutter Supabase Dependencies

### Minor Flaws & Gotchas to Watch Out For
While the SQL is sound, there are two operational "gotchas" in how your Flutter app must interact with this specific schema:

**1. The Auth Meta-Data Trap (Critical for Sign-up)**
Look at your `handle_new_user` trigger:
```sql
COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'patient')
```
* **The Flaw:** If your Flutter app calls `Supabase.instance.client.auth.signUp(email: e, password: p)` without explicitly passing `data`, every single user will be created as a `'patient'` named `'User'`.
* **The Fix:** You must pass `full_name` and `role` inside the `data` parameter during the Flutter sign-up call (detailed in the Flutter section below).

**2. Storage Policy Folder Enforcement**
Look at your Storage RLS policy:
```sql
WITH CHECK (bucket_id = 'reports' AND auth.uid()::text = (storage.foldername(name))[1]);
```
* **The Flaw:** This policy strictly dictates that a user can only upload a file if the root folder name perfectly matches their `auth.uid()`.
* **The Fix:** When uploading files from Flutter, your path must strictly follow this structure: `'${user.id}/filename.pdf'`. If you try to upload to a generic `'/scans/filename.pdf'`, Supabase will reject it with a 403 error.

---

### Connecting Supabase to the Flutter Project

Here is the exact implementation path to wire your configured backend to your Flutter app.

**1. Add Dependencies**
In your `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.8.0
  flutter_dotenv: ^5.2.1
```

**2. Initialize Supabase**
In your `main.dart`, initialize the environment variables and the Supabase client before `runApp`.

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!, 
  );

  runApp(const VoxMedApp());
}

final supabase = Supabase.instance.client;
```

**3. The Crucial Sign-Up Implementation**
To satisfy your `handle_new_user` trigger, your sign-up function must look exactly like this:

```dart
Future<void> signUpUser(String email, String password, String fullName, String role) async {
  try {
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName, // Maps to raw_user_meta_data->>'full_name'
        'role': role,          // Maps to raw_user_meta_data->>'role'
      },
    );
    // Profile is automatically created in the database via the Postgres Trigger
  } catch (e) {
    print('Sign up error: $e');
  }
}
```

**4. The Crucial Storage Upload Implementation**
To satisfy your Storage RLS policies, your upload logic must structure the file path using the user's ID:

```dart
Future<void> uploadMedicalReport(File file, String fileName) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final filePath = '${user.id}/$fileName'; // Strictly requires user.id as the root folder

  try {
    await supabase.storage
      .from('reports')
      .upload(filePath, file);
      
    // Next: Insert a row into the medical_records table referencing this file
  } catch (e) {
    print('Upload error: $e');
  }
}
```

Would you like to draft the Supabase Edge Function (in TypeScript/Deno) that will intercept the uploaded prescription images and send them to the Gemini API for OCR extraction?
---

## Entity Relationship Summary

```
profiles ─────────── 1:1 ──── doctors
    │                            │
    │ 1:N                       │ 1:N
    ▼                            ▼
appointments ◄──── N:1 ──── doctor_schedules
    │                            │
    │ 1:N                       │ 1:N
    ▼                            ▼
medical_records              doctor_absences
    
profiles ─── 1:N ──── prescriptions ─── 1:N ──── prescription_items
                          │                            │
                          │ 1:N                       │ 1:N
                          ▼                            ▼
                   prescription_renewals         adherence_logs

profiles ─── 1:N ──── ai_conversations ─── 1:N ──── ai_messages

doctors ─── 1:N ──── consultation_sessions ─── 1:N ──── consultation_members
                          │
                          │ 1:N
                          ▼
                   consultation_messages

profiles ─── 1:N ──── notifications
profiles ─── 1:N ──── reviews ──── N:1 ──── doctors
profiles ─── 1:N ──── wearable_data

doctors ─── N:1 ──── hospitals
```


