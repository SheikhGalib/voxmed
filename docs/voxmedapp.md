# VoxMed Connect — Complete System Documentation
> **Covers:** Flutter Mobile App (Patient & Doctor) + React Web Management Dashboard (Hospital Admin / Receptionist / Lab Staff / Platform Admin)
> **Last Updated:** 2026-04-25

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Dual-Platform Architecture](#2-dual-platform-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Roles & Access Control](#4-roles--access-control)
5. [Database Schema (Shared)](#5-database-schema-shared)
6. [Mobile App — Patient Features](#6-mobile-app--patient-features)
7. [Mobile App — Doctor Features](#7-mobile-app--doctor-features)
8. [Web Management Dashboard](#8-web-management-dashboard)
9. [AI & Edge Function Layer](#9-ai--edge-function-layer)
10. [API Endpoints](#10-api-endpoints)
11. [Frontend Route Maps](#11-frontend-route-maps)
12. [Security Model](#12-security-model)
13. [Diagrams](#13-diagrams)
    - 13.1 Context Diagram (DFD Level 0)
    - 13.2 DFD Level 1
    - 13.3 DFD Level 2 — Appointment Management
    - 13.4 DFD Level 2 — AI Triage Subsystem
    - 13.5 ER Diagram
    - 13.6 Class Diagram
    - 13.7 Use Case Diagram
    - 13.8 Activity Diagram — Patient Books Appointment
    - 13.9 Activity Diagram — Doctor Approves Prescription Renewal
    - 13.10 Sequence Diagram — Appointment Booking
    - 13.11 Sequence Diagram — OCR Record Upload
    - 13.12 Workflow Diagram (System-wide)
14. [Development Phases & Status](#14-development-phases--status)
15. [Screen Inventory](#15-screen-inventory)

---

## 1. Project Overview

**VoxMed Connect** is an integrated, role-based healthcare management ecosystem built on a shared Supabase backend. It consists of two distinct frontends that together serve six distinct user roles:

| Platform | Technology | Serves |
|---|---|---|
| **Mobile App** | Flutter (Android / iOS) | Patients, Doctors |
| **Web Dashboard** | React 18 + Vite + Tailwind | Hospital Admins, Receptionists, Lab Staff, Platform Admin |

### Core Problems Addressed

| Problem | Solution |
|---|---|
| **Compliance Gap** | Voice-driven adherence engine tracks medication intake in real-time |
| **Scheduling Friction** | Auto-rescheduling via Edge Functions when doctor is absent |
| **Siloed Health Data** | Universal Health Passport aggregates all records across providers |
| **Administrative Burnout** | Ambient AI auto-generates SOAP notes during consultations |
| **Decentralized Hospital Operations** | Web dashboard centralises doctor management, appointments, lab, and revenue |

---

## 2. Dual-Platform Architecture

```
┌───────────────────────────┐     ┌─────────────────────────────────────┐
│     Flutter Mobile App     │     │       React Web Dashboard           │
│   (Patient & Doctor)       │     │   (Admin / Hospital / Staff)        │
│                            │     │                                     │
│  Riverpod State Mgmt       │     │  React Router v6, React Query       │
│  GoRouter (auth guard)     │     │  Tailwind CSS, DashboardLayout      │
│  Repository Pattern        │     │  AuthContext → ProtectedRoute       │
└───────────┬────────────────┘     └────────────┬────────────────────────┘
            │ Supabase Flutter SDK               │ HTTP / JWT Bearer (Express)
            │ (anon/user JWT — RLS applies)      │ (service_role key — bypasses RLS)
            ▼                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          Supabase (PostgreSQL)                        │
│                                                                       │
│  auth.users ──► profiles (role enum)                                  │
│  hospitals, hospital_staff, departments                               │
│  doctors, doctor_schedules, doctor_absences                           │
│  appointments, medical_tests                                          │
│  medical_records, payments                                            │
│  prescriptions, prescription_items, prescription_renewals             │
│  adherence_logs, ai_conversations, ai_messages                        │
│  notifications, reviews, wearable_data                               │
│  consultation_sessions, consultation_members, consultation_messages   │
│  video_calls, call_transcripts, emergency_call_requests               │
│  VIEW: public_doctors                                                 │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
              ┌─────────────────┼──────────────────┐
              ▼                 ▼                  ▼
   ┌────────────────┐  ┌──────────────────┐  ┌─────────────────────┐
   │ Supabase Auth  │  │ Supabase Storage │  │  Edge Functions     │
   │ JWT + RLS      │  │ avatars/         │  │  gemini-ocr         │
   │                │  │ reports/         │  │  gemini-triage      │
   │                │  │ prescriptions/   │  │  auto-reschedule    │
   │                │  │                  │  │  soap-notes         │
   │                │  │                  │  │  medication-reminder│
   └────────────────┘  └──────────────────┘  └─────────────────────┘
```

---

## 3. Tech Stack

### Mobile App (Flutter)

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Material 3) |
| Language | Dart |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigation | GoRouter (auth guard + role-based shell routes) |
| Data Layer | Repository Pattern (Supabase PostgREST) |
| AI / Voice | Google Gemini API (via Edge Functions) |
| Speech Input | `speech_to_text ^7.3.0` |
| TTS Output | `flutter_tts ^4.2.5` |
| Camera/Gallery | `image_picker` |
| Deep Links | `app_links` |
| Local Storage | `shared_preferences` |
| HTTP | Supabase Flutter SDK (PostgREST + Realtime WebSockets) |
| Design System | Manrope + Inter fonts, green primary palette |

### Web Dashboard (React + Node.js)

| Layer | Technology |
|---|---|
| Frontend | React 18, Vite, React Router v6, Tailwind CSS |
| Backend | Node.js, Express |
| Validation | Zod (request body schemas) |
| Security | Helmet, CORS whitelist, express-rate-limit |
| Auth | Supabase JWT verification (`authenticate()` middleware) |
| Deployment | Vercel (client + server via `vercel.json`) |

### Shared Backend

| Layer | Technology |
|---|---|
| Database | Supabase PostgreSQL (PostgREST auto-API) |
| Authentication | Supabase Auth (JWT, RLS) |
| Storage | Supabase Storage (avatars, reports, prescriptions) |
| Realtime | Supabase Realtime (WebSockets) — chat, notifications |
| Serverless | Supabase Edge Functions (Deno) |
| AI Processing | Google Gemini API (OCR, NLP triage, SOAP notes) |
| Currency | Bangladeshi Taka (BDT ৳) |

---

## 4. Roles & Access Control

### Role Definitions

| Role | Platform | Description |
|---|---|---|
| `patient` | Mobile App | Books appointments, manages health passport, interacts with AI |
| `doctor` | Mobile App | Manages schedule, reviews patients, approves prescription renewals |
| `hospital_admin` | Web Dashboard | Manages one hospital — doctors, staff, tests, appointments, profit |
| `receptionist` | Web Dashboard | Views schedules and books appointments on behalf of patients |
| `lab_staff` | Web Dashboard | Looks up patients and uploads lab reports |
| `admin` | Web Dashboard | Platform superadmin — approves hospitals/doctors, views revenue |

### Mobile App Auth Guard (GoRouter)

```
App Launch → check Supabase session
  → No session → /login
  → Patient role → Patient Shell (4 tabs: Home, Find Care, Passport, Profile)
  → Doctor role  → Doctor Shell (3 tabs: Dashboard, Patients, Profile)
```

### Web Dashboard Middleware Chain

```
Request → authenticate() → authorize(role) → attachHospital() → Route handler
```

- **`authenticate()`** — Verifies Bearer JWT via Supabase, loads `profiles` row, attaches `req.user`
- **`authorize(...roles)`** — Checks role against allowed roles; returns 403 if mismatch
- **`attachHospital()`** — Resolves `hospital_id` from `hospital_staff`; staff cannot access other hospitals

---

## 5. Database Schema (Shared)

> This database is shared between the Flutter mobile app and the React web dashboard. Both read/write the same Supabase project.

### Enum Types

```sql
user_role         :: admin | hospital_admin | receptionist | lab_staff | doctor | patient
hospital_status   :: pending | approved | rejected
doctor_status     :: pending | approved | rejected
appointment_status:: scheduled | completed | cancelled | no_show
payment_status    :: pending | paid | refunded
prescription_status :: active | completed | cancelled
renewal_status    :: pending | approved | rejected
```

### Core Tables (19 total)

#### `profiles`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | References `auth.users.id` (CASCADE) |
| `role` | user_role | Default: `patient` |
| `full_name` | TEXT | NOT NULL |
| `email` | TEXT | UNIQUE |
| `phone` | TEXT | |
| `date_of_birth` | DATE | |
| `gender` | TEXT | male / female / other |
| `blood_group` | TEXT | e.g. A+, O- |
| `address` | TEXT | |
| `avatar_url` | TEXT | Path in `avatars` bucket |
| `emergency_contact` | JSONB | `{ name, phone, relation }` |
| `created_at / updated_at` | TIMESTAMPTZ | Auto-managed |

#### `hospitals`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `name` | TEXT | NOT NULL |
| `address / city / state / country` | TEXT | |
| `latitude / longitude` | FLOAT8 | For proximity search |
| `phone / email / website` | TEXT | |
| `logo_url / cover_image_url` | TEXT | |
| `operating_hours` | JSONB | `{ mon: {open,close}, ... }` |
| `services` | TEXT[] | e.g. `{Radiology, ICU}` |
| `rating` | FLOAT4 | Aggregate |
| `status` | hospital_status | Default: `pending` |
| `approved_by` | UUID FK → profiles | Platform admin |
| `profit_earned` | NUMERIC | Platform-level profit |

#### `hospital_staff`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `hospital_id` | UUID FK → hospitals | |
| `profile_id` | UUID FK → profiles | |
| `role` | user_role | receptionist / lab_staff / admin |

#### `departments`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `hospital_id` | UUID FK | |
| `name / description` | TEXT | |

#### `doctors`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `profile_id` | UUID FK → profiles | UNIQUE |
| `hospital_id` | UUID FK → hospitals | NULLABLE |
| `specialty / sub_specialty` | TEXT | |
| `qualifications` | TEXT[] | e.g. `{MBBS, MD}` |
| `experience_years` | INT | |
| `license_number` | TEXT | |
| `consultation_fee` | NUMERIC | In BDT |
| `rating / patients_count / reviews_count` | FLOAT/INT | Aggregates |
| `status` | doctor_status | Default: `pending` |
| `approved_by_hospital` | BOOLEAN | Set true by hospital admin |
| `is_available` | BOOLEAN | Set true on approval |

#### `doctor_schedules`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `doctor_id` | UUID FK | |
| `day_of_week` | INT2 (0–6) | 0=Sunday |
| `start_time / end_time` | TIME | |
| `slot_duration_minutes` | INT | Default: 30 |
| `is_active` | BOOLEAN | |

Unique: `(doctor_id, day_of_week, start_time)`

#### `appointments`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `patient_id` | UUID FK → profiles | |
| `doctor_id` | UUID FK → doctors | |
| `hospital_id` | UUID FK → hospitals | |
| `appointment_date / appointment_time` | DATE / TIME | |
| `status` | appointment_status | Default: `scheduled` |
| `reason / notes` | TEXT | |
| `booked_by` | UUID FK → profiles | Staff who booked (web) |

#### `medical_records`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `patient_id` | UUID FK → profiles | |
| `doctor_id / hospital_id` | UUID FK | Nullable |
| `test_id` | UUID FK → medical_tests | Nullable |
| `appointment_id` | UUID FK | Nullable |
| `report_url` | TEXT | Supabase Storage URL |
| `report_name / diagnosis / notes` | TEXT | |
| `uploaded_by` | UUID FK → profiles | |

#### `prescriptions`, `prescription_items`, `prescription_renewals`

Prescriptions are issued by doctors. Items list individual medications (name, dosage, frequency, duration). Renewals are AI-triggered requests routed to the doctor's approval queue.

#### `adherence_logs`

Tracks patient responses to medication reminders (taken / missed / snoozed).

| Column | Type | Notes |
|---|---|---|
| `prescription_item_id` | UUID FK | |
| `scheduled_time` | TIMESTAMPTZ | |
| `response` | TEXT | taken / missed / snoozed |
| `responded_at` | TIMESTAMPTZ | |

#### `ai_conversations`, `ai_messages`

Store conversational AI triage sessions between patients and the Gemini-powered assistant.

#### `consultation_sessions`, `consultation_members`, `consultation_messages`

Multi-doctor collaborative care sessions with real-time messaging via Supabase Realtime.

#### `notifications`

| Column | Type | Notes |
|---|---|---|
| `user_id` | UUID FK | Recipient |
| `type` | TEXT | appointment / medication / renewal / system |
| `title / body` | TEXT | |
| `data` | JSONB | Deep-link context |
| `is_read` | BOOLEAN | |

#### `payments`, `medical_tests`, `reviews`, `wearable_data`

Supporting tables for billing (split between hospital profit and platform admin profit), diagnostic tests, patient reviews of doctors, and wearable biometric data (heart rate, SpO2, sleep).

### View: `public_doctors`

Exposes only fully approved, available doctors to the Flutter app (anonymous reads allowed):

```sql
SELECT d.*, p.full_name, p.avatar_url, h.name AS hospital_name
FROM doctors d
JOIN profiles p ON d.profile_id = p.id
LEFT JOIN hospitals h ON d.hospital_id = h.id
WHERE d.status = 'approved'
  AND d.approved_by_hospital = true
  AND d.is_available = true;
```

### Row Level Security (RLS) Summary

| Table | RLS Policy |
|---|---|
| profiles | Own row read/write; service_role full access |
| hospitals | Public read if `approved`; admin write own row |
| doctors | Public read via `public_doctors` view; service_role full |
| appointments | Patient reads own rows; service_role full |
| medical_records | Patient reads own rows; service_role full |
| adherence_logs | Patient reads own rows |
| notifications | User reads own rows |
| All others | service_role only |

---

## 6. Mobile App — Patient Features

### 6.1 Home Dashboard

- Greeting card with patient name and avatar
- Digital health passport quick-access card (navigates to Passport tab)
- Upcoming appointments list (live from `appointments` table)
- Recent lab reports (live from `medical_records`)
- AI assistant FAB (wave animation, "Hi" bubble on first visit)
- Notifications bell

### 6.2 Find Care (Doctor / Hospital Discovery)

- Search by hospital name, doctor name, or specialty
- Filter by: specialty, rating, availability, city
- Hospital listing → tap → view affiliated doctors
- Doctor card → tap → Doctor Booking Detail screen
  - Profile, qualifications, bio, consultation fee, rating, reviews
  - Weekly schedule availability
  - "Book Appointment" CTA

### 6.3 Appointment Booking Flow

1. Select available date/time slot (from `doctor_schedules`)
2. Enter reason for visit
3. Confirm → `appointments` insert → Supabase Realtime push to doctor
4. Confirmation screen with appointment summary

### 6.4 Smart Health Passport

- View all medical records grouped by date
- View active and past prescriptions
- Upload new records via:
  - Device camera (OCR trigger)
  - Gallery picker
- Record uploads → Supabase Storage → `medical_records` insert
- OCR: `gemini-ocr` Edge Function extracts structured data from prescription images

### 6.5 Health Analytics Dashboard

- Wearable integration: heart rate, SpO2, sleep quality, step count
- Medication adherence score (derived from `adherence_logs`)
- Long-term health trend charts
- Appointment history timeline

### 6.6 AI Triage Assistant

- Conversational interface powered by Gemini API (via `gemini-triage` Edge Function)
- Patient describes symptoms → AI provides triage guidance + specialist recommendation + doctor list
- Voice input via `speech_to_text`; voice output via `flutter_tts`
- All conversations stored in `ai_conversations` / `ai_messages`
- Proactive medication reminder scheduling (local notifications)

### 6.7 Prescription Renewal Requests

- View active prescriptions
- When supply is running low, AI prompts a renewal request
- Renewal submitted to `prescription_renewals` table → routed to doctor's approval queue
- Real-time status update on approval/rejection

### 6.8 Profile & Settings

- Edit profile (name, phone, address, date of birth, blood group, emergency contact)
- Avatar upload to `avatars` bucket
- Notification preferences
- Sign out

---

## 7. Mobile App — Doctor Features

### 7.1 Clinical Dashboard

- Today's appointment list with patient compliance scores
- Live "Compliance Score" card — aggregated from `adherence_logs` for each patient
- Pending prescription renewal requests count
- Emergency Absence button → triggers `auto-reschedule` Edge Function

### 7.2 Patient Management

- View all assigned patients
- Patient detail screen:
  - Universal Health Passport (all records, prescriptions, adherence logs)
  - Lab results uploaded by `lab_staff`
  - Wearable biometric trend

### 7.3 Prescription Approval Queue

- List of pending renewal requests
- Per-request view: medication details, adherence history, patient notes
- Actions: Approve / Modify dosage / Reject
- Approved renewals trigger a notification to the patient

### 7.4 Live Consultation & SOAP Notes

- Video consultation interface (`video_calls` table)
- Ambient listening mode → audio transcribed in real-time
- `soap-notes` Edge Function generates standardised SOAP note from transcript
- Note auto-attached to `medical_records` for the patient

### 7.5 Collaborative Care Hub

- Create a multi-doctor consultation session (`consultation_sessions`)
- Invite specialist doctors as members (`consultation_members`)
- Share patient record within the session
- Real-time chat via `consultation_messages` (Supabase Realtime WebSockets)
- All participants see the same patient data snapshot

### 7.6 Doctor Schedule Management

- Set weekly availability slots (`doctor_schedules`)
- Toggle slot active/inactive
- View upcoming confirmed appointments

---

## 8. Web Management Dashboard

### 8.1 Platform Admin (role: `admin`)

**Route prefix: `/admin`**

| Page | Purpose |
|---|---|
| Dashboard | Platform-wide stats: total hospitals, doctors, appointments, revenue |
| Manage Hospitals | List all hospitals; approve/reject pending registrations |
| Manage Doctors | List all doctors; approve/reject (platform-level) |
| Manage Users | View all user profiles; deactivate accounts |
| Revenue Dashboard | Platform profit breakdown by hospital; payment history |

### 8.2 Hospital Admin (role: `hospital_admin`)

**Route prefix: `/hospital`**

| Page | Purpose |
|---|---|
| Dashboard | Hospital stats: doctors, staff, today's appointments, monthly revenue |
| Doctors | List hospital doctors; approve/reject; view schedules |
| Staff | Add/remove receptionists and lab staff |
| Medical Tests | CRUD for diagnostic tests; set pricing and profit split |
| Appointments | View all hospital appointments |
| Reports | Browse all medical records uploaded for hospital patients |
| Profit | Detailed profit breakdown: appointment fees, test revenue, splits |

### 8.3 Receptionist (role: `receptionist`)

**Route prefix: `/receptionist`**

| Page | Purpose |
|---|---|
| Schedules | View available doctor slots for today/week |
| Book Appointment | Select doctor → slot → enter patient → confirm booking |

### 8.4 Lab Staff (role: `lab_staff`)

**Route prefix: `/lab`**

| Page | Purpose |
|---|---|
| Patients | Search patients by name or ID; view their existing records |
| Upload Report | Select patient → select test type → upload PDF/image → save record |

---

## 9. AI & Edge Function Layer

All AI processing is server-side via Supabase Edge Functions (Deno runtime). API keys are never exposed to the client.

| Function | Trigger | Input | Output |
|---|---|---|---|
| `gemini-ocr` | Patient uploads prescription/report image | Image from Supabase Storage | Structured data: medication name, dosage, doctor, date → saved to `medical_records` |
| `gemini-triage` | Patient sends message to AI assistant | Symptom text + conversation history | Triage guidance + specialty recommendation + doctor suggestions |
| `auto-reschedule` | Doctor triggers Emergency Absence | Doctor ID + absence date | Finds next available slots for all affected appointments; updates `appointments`; sends notifications |
| `soap-notes` | Consultation session ends | Audio transcript | Formatted SOAP note text → inserted as `medical_records` entry |
| `medication-reminder` | Cron scheduler | Adherence schedule from DB | Push notifications for medication reminders |

---

## 10. API Endpoints

### Auth (Web Dashboard) — `/api/auth`

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/hospitals` | Public | List approved hospitals |
| POST | `/signup` | Public | Register hospital admin + create hospital |
| POST | `/signin` | Public | Sign in, return JWT + profile |
| POST | `/doctor-signup` | Public | Register doctor under a hospital |
| POST | `/refresh` | Public | Refresh JWT |
| GET | `/me` | Authenticated | Get current user profile |

### Admin — `/api/admin`

| Method | Path | Description |
|---|---|---|
| GET | `/hospitals` | List all hospitals |
| PATCH | `/hospitals/:id/approve` | Approve hospital |
| PATCH | `/hospitals/:id/reject` | Reject hospital |
| GET | `/doctors` | List all doctors |
| PATCH | `/doctors/:id/approve` | Approve doctor |
| PATCH | `/doctors/:id/reject` | Reject doctor |
| GET | `/users` | List all users |
| GET | `/revenue` | Platform revenue summary |

### Hospital — `/api/hospital`

| Method | Path | Description |
|---|---|---|
| GET | `/dashboard` | Hospital stats |
| GET/PATCH | `/doctors`, `/doctors/:id/approve`, `/doctors/:id/reject` | Doctor management |
| GET/POST/DELETE | `/staff`, `/staff/:id` | Staff management |
| GET/POST/PUT/DELETE | `/tests`, `/tests/:id` | Medical test CRUD |
| GET | `/appointments` | List appointments |
| GET | `/reports` | Medical records |
| GET | `/profit` | Profit breakdown |

### Receptionist — `/api/receptionist`

| Method | Path | Description |
|---|---|---|
| GET | `/schedules` | Doctor schedules |
| GET | `/doctors` | Available doctors |
| POST | `/appointments` | Book appointment |

### Lab — `/api/lab`

| Method | Path | Description |
|---|---|---|
| GET | `/patients` | List patients |
| POST | `/upload` | Upload report |

---

## 11. Frontend Route Maps

### Flutter Mobile App (GoRouter)

```
/                         → redirect (auth guard)
/login                    → LoginScreen
/register                 → RegisterScreen

/patient/*                → PatientShell (4-tab ShellRoute)
  /patient/home           → DashboardScreen
  /patient/find-care      → FindCareScreen
    /patient/find-care/doctor/:id → DoctorBookingDetailScreen
  /patient/passport       → HealthPassportScreen
    /patient/passport/analytics  → HealthAnalyticsScreen
    /patient/passport/scan       → ScanRecordsScreen
    /patient/passport/renewals   → PrescriptionRenewalsScreen
  /patient/profile        → ProfileScreen

/patient/ai-assistant     → AiAssistantScreen (above nav)

/doctor/*                 → DoctorShell (3-tab ShellRoute)
  /doctor/dashboard       → ClinicalDashboardScreen
  /doctor/patients        → MyPatientsScreen
    /doctor/patients/:id  → PatientDetailScreen
    /doctor/patients/:id/chat → DoctorChatScreen
  /doctor/schedule        → DoctorScheduleScreen
  /doctor/approval-queue  → ApprovalQueueScreen
  /doctor/collaborative-hub → CollaborativeHubScreen
  /doctor/live-consultation/:sessionId → LiveConsultationScreen
  /doctor/profile         → ProfileScreen
```

### React Web Dashboard (React Router v6)

```
/login                    → LoginPage
/register                 → RegisterPage
/unauthorized             → Unauthorized

/admin                    → AdminDashboard         [role: admin]
/admin/hospitals          → ManageHospitals
/admin/doctors            → ManageDoctors
/admin/users              → ManageUsers
/admin/revenue            → RevenueDashboard

/hospital                 → HospitalDashboard      [role: hospital_admin]
/hospital/doctors         → HospitalDoctors
/hospital/staff           → HospitalStaff
/hospital/tests           → HospitalTests
/hospital/appointments    → HospitalAppointments
/hospital/reports         → HospitalReports
/hospital/profit          → HospitalProfit

/receptionist             → ReceptionistSchedules  [role: receptionist]
/receptionist/book        → ReceptionistBook

/lab                      → LabPatients            [role: lab_staff]
/lab/upload               → LabUpload
```

---

## 12. Security Model

| Concern | Implementation |
|---|---|
| **Transport** | HTTPS enforced; CORS whitelist (localhost + Vercel domains) |
| **Headers** | `helmet()` sets CSP, HSTS, X-Frame-Options on web backend |
| **Rate Limiting** | 100 requests / 15 min per IP on `/api/` (web) |
| **Authentication** | Supabase JWT verified server-side (web) / client-side (mobile) on every request |
| **Authorisation (Web)** | Role checked via `authorize()` middleware before any DB operation |
| **Authorisation (Mobile)** | GoRouter auth guard; RLS enforces data access at DB level |
| **Hospital Scoping** | `attachHospital()` resolves `hospital_id` from `hospital_staff`; cross-hospital data access is impossible |
| **Row Level Security** | RLS enabled on all tables; service_role key used server-side only (never in mobile app) |
| **Input Validation** | Zod schemas (web); client-side form validators (mobile) |
| **File Storage** | Supabase Storage with bucket-level access policies |
| **API Keys** | Gemini API key held in Supabase Edge Function secrets only |

---

## 13. Diagrams

### 13.1 Context Diagram (DFD Level 0)

```mermaid
flowchart TB
    P["👤 Patient"]
    D["🩺 Doctor"]
    HA["🏥 Hospital Admin"]
    PA["👑 Platform Admin"]
    G["🤖 Google Gemini API"]
    W["⌚ Wearable Devices"]
    N["🔔 Push Notification\nService"]
    R["📋 Receptionist"]
    L["🔬 Lab Staff"]

    P -->|"Sign up, book appointments,\nupload records, chat AI,\ntrack medications"| V["VoxMed Connect\nSystem"]
    V -->|"Confirmations, health data,\nAI results, reminders"| P

    D -->|"Manage schedule, view patients,\napprove renewals, collaborate"| V
    V -->|"Patient compliance data,\nrenewal requests, SOAP notes"| D

    HA -->|"Manage doctors, staff,\ntests, reports"| V
    V -->|"Hospital stats, profit reports"| HA

    PA -->|"Approve hospitals/doctors,\nview revenue"| V
    V -->|"Platform analytics"| PA

    R -->|"Book appointments\nfor patients"| V
    L -->|"Upload lab reports"| V

    V <-->|"Symptom text, images, audio"| G
    W -->|"Biometric data"| V
    V -->|"Reminders, alerts"| N
```

---

### 13.2 DFD Level 1

```mermaid
flowchart TB
    P["👤 Patient"]
    D["🩺 Doctor"]
    W["🌐 Web Users\n(Admin/HA/Recep/Lab)"]
    G["🤖 Gemini API"]

    subgraph VoxMed["VoxMed Connect System"]
        direction TB
        P1["1.0\nAuthentication\n& Profile"]
        P2["2.0\nAppointment\nManagement"]
        P3["3.0\nHealth Passport\n& Records"]
        P4["4.0\nPrescription\n& Adherence"]
        P5["5.0\nAI Triage\nAssistant"]
        P6["6.0\nDoctor Clinical\nTools"]
        P7["7.0\nCollaborative\nCare"]
        P8["8.0\nNotification\nEngine"]
        P9["9.0\nWeb Management\nDashboard"]
    end

    DB[("Supabase\nPostgreSQL")]
    ST[("Supabase\nStorage")]

    P & D -->|"Credentials, profile"| P1
    P1 <-->|"profiles"| DB

    P -->|"Booking request"| P2
    D -->|"Schedule, absence"| P2
    W -->|"Book for patient"| P2
    P2 <-->|"appointments,\ndoctor_schedules"| DB

    P -->|"Upload scan"| P3
    P3 <-->|"medical_records"| DB
    P3 <-->|"Images/PDFs"| ST
    P3 -->|"Image"| G
    G -->|"OCR result"| P3

    P -->|"Adherence response"| P4
    D -->|"Approve/reject renewal"| P4
    P4 <-->|"prescriptions,\nadherence_logs,\nrenewal_requests"| DB

    P -->|"Symptom text"| P5
    P5 -->|"Prompt"| G
    G -->|"Triage response"| P5
    P5 <-->|"ai_conversations,\nai_messages"| DB

    D -->|"View patients, set absence"| P6
    P6 <-->|"doctors, appointments,\nadherence_logs"| DB

    D -->|"Create session"| P7
    P7 <-->|"consultation_sessions,\nconsultation_messages"| DB

    P8 <-->|"notifications"| DB

    W -->|"Manage operations"| P9
    P9 <-->|"hospitals, hospital_staff,\npayments, medical_tests"| DB
```

---

### 13.3 DFD Level 2 — Appointment Management (Process 2.0)

```mermaid
flowchart LR
    P["👤 Patient"]
    D["🩺 Doctor"]
    R["📋 Receptionist"]
    EF["⚡ auto-reschedule\nEdge Function"]

    P & R -->|"Book request:\ndoctorId, date, time"| P2_1["2.1\nValidate &\nCreate Slot"]
    P2_1 -->|"Check availability"| DS[("doctor_schedules")]
    P2_1 -->|"Insert appointment"| AP[("appointments")]
    AP -->|"Confirmation"| P2_2["2.2\nSend\nConfirmation"]
    P2_2 -->|"Notification"| P
    P2_2 -->|"Notification"| D

    D -->|"Emergency absence"| P2_3["2.3\nTrigger\nAuto-Reschedule"]
    P2_3 -->|"Invoke"| EF
    EF -->|"Read affected appointments"| AP
    EF -->|"Find new slots"| DS
    EF -->|"Update appointments"| AP
    EF -->|"Reschedule alerts"| P

    P -->|"Cancel request"| P2_4["2.4\nCancel\nAppointment"]
    P2_4 -->|"Update status=cancelled"| AP
    P2_4 -->|"Cancel notification"| D

    D -->|"Mark complete/no-show"| P2_5["2.5\nUpdate\nStatus"]
    P2_5 -->|"Update status"| AP
    P2_5 -->|"Trigger payment record"| PAY[("payments")]
```

---

### 13.4 DFD Level 2 — AI Triage Subsystem (Process 5.0)

```mermaid
flowchart LR
    P["👤 Patient"]
    G["🤖 Gemini API"]

    P -->|"Symptom description\n(text or voice)"| P5_1["5.1\nSpeech-to-Text\n(if voice)"]
    P5_1 -->|"Transcribed text"| P5_2["5.2\nSession\nManagement"]
    P5_2 -->|"Load conversation history"| CONV[("ai_conversations\nai_messages")]
    P5_2 -->|"Assembled prompt"| P5_3["5.3\nGemini\nAPI Call\n(Edge Function)"]
    G -->|"Triage response\n+ doctor suggestions"| P5_3
    P5_3 -->|"Save assistant message"| CONV
    P5_3 -->|"Triage result"| P5_4["5.4\nPresent Results\n+ Doctor List"]
    P5_4 -->|"Query approved doctors"| DOC[("public_doctors\nview")]
    P5_4 -->|"Triage guidance +\nmatched doctors"| P
    P5_4 -->|"TTS output\n(if voice mode)"| P
```

---

### 13.5 ER Diagram

```mermaid
erDiagram
    AUTH_USERS {
        uuid id PK
        text email
    }
    PROFILES {
        uuid id PK
        text role
        text full_name
        text email
        text phone
        date date_of_birth
        text gender
        text blood_group
        text avatar_url
        jsonb emergency_contact
    }
    HOSPITALS {
        uuid id PK
        text name
        text city
        text status
        float8 latitude
        float8 longitude
        text services
        float4 rating
        numeric profit_earned
    }
    HOSPITAL_STAFF {
        uuid id PK
        uuid hospital_id FK
        uuid profile_id FK
        text role
    }
    DEPARTMENTS {
        uuid id PK
        uuid hospital_id FK
        text name
    }
    DOCTORS {
        uuid id PK
        uuid profile_id FK
        uuid hospital_id FK
        text specialty
        text qualifications
        numeric consultation_fee
        float4 rating
        text status
        boolean approved_by_hospital
        boolean is_available
    }
    DOCTOR_SCHEDULES {
        uuid id PK
        uuid doctor_id FK
        int2 day_of_week
        time start_time
        time end_time
        int4 slot_duration_minutes
    }
    APPOINTMENTS {
        uuid id PK
        uuid patient_id FK
        uuid doctor_id FK
        uuid hospital_id FK
        date appointment_date
        time appointment_time
        text status
        uuid booked_by FK
    }
    MEDICAL_RECORDS {
        uuid id PK
        uuid patient_id FK
        uuid doctor_id FK
        uuid hospital_id FK
        uuid test_id FK
        uuid appointment_id FK
        text report_url
        text diagnosis
        uuid uploaded_by FK
    }
    PRESCRIPTIONS {
        uuid id PK
        uuid patient_id FK
        uuid doctor_id FK
        text status
    }
    PRESCRIPTION_ITEMS {
        uuid id PK
        uuid prescription_id FK
        text medication_name
        text dosage
        text frequency
        int4 duration_days
    }
    PRESCRIPTION_RENEWALS {
        uuid id PK
        uuid prescription_id FK
        uuid patient_id FK
        uuid doctor_id FK
        text status
    }
    ADHERENCE_LOGS {
        uuid id PK
        uuid prescription_item_id FK
        uuid patient_id FK
        timestamptz scheduled_time
        text response
    }
    MEDICAL_TESTS {
        uuid id PK
        uuid hospital_id FK
        text name
        numeric price
        decimal hospital_profit_percent
        decimal admin_profit_percent
    }
    PAYMENTS {
        uuid id PK
        uuid appointment_id FK
        uuid patient_id FK
        uuid hospital_id FK
        numeric amount
        numeric admin_profit
        numeric hospital_profit
        text status
    }
    AI_CONVERSATIONS {
        uuid id PK
        uuid patient_id FK
    }
    AI_MESSAGES {
        uuid id PK
        uuid conversation_id FK
        text role
        text content
    }
    CONSULTATION_SESSIONS {
        uuid id PK
        uuid primary_doctor_id FK
        uuid patient_id FK
    }
    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        text type
        boolean is_read
    }
    REVIEWS {
        uuid id PK
        uuid doctor_id FK
        uuid patient_id FK
        int2 rating
        text comment
    }

    AUTH_USERS ||--|| PROFILES : "trigger insert"
    PROFILES ||--o{ HOSPITALS : "approved_by"
    PROFILES ||--o{ HOSPITAL_STAFF : "profile_id"
    PROFILES ||--o{ DOCTORS : "profile_id"
    PROFILES ||--o{ APPOINTMENTS : "patient_id"
    PROFILES ||--o{ APPOINTMENTS : "booked_by"
    PROFILES ||--o{ MEDICAL_RECORDS : "patient_id"
    PROFILES ||--o{ PRESCRIPTIONS : "patient_id"
    PROFILES ||--o{ ADHERENCE_LOGS : "patient_id"
    PROFILES ||--o{ NOTIFICATIONS : "user_id"
    HOSPITALS ||--o{ HOSPITAL_STAFF : "hospital_id"
    HOSPITALS ||--o{ DEPARTMENTS : "hospital_id"
    HOSPITALS ||--o{ DOCTORS : "hospital_id"
    HOSPITALS ||--o{ MEDICAL_TESTS : "hospital_id"
    HOSPITALS ||--o{ APPOINTMENTS : "hospital_id"
    HOSPITALS ||--o{ PAYMENTS : "hospital_id"
    DOCTORS ||--o{ DOCTOR_SCHEDULES : "doctor_id"
    DOCTORS ||--o{ APPOINTMENTS : "doctor_id"
    DOCTORS ||--o{ PRESCRIPTIONS : "doctor_id"
    DOCTORS ||--o{ REVIEWS : "doctor_id"
    APPOINTMENTS ||--o{ MEDICAL_RECORDS : "appointment_id"
    APPOINTMENTS ||--o{ PAYMENTS : "appointment_id"
    PRESCRIPTIONS ||--o{ PRESCRIPTION_ITEMS : "prescription_id"
    PRESCRIPTIONS ||--o{ PRESCRIPTION_RENEWALS : "prescription_id"
    PRESCRIPTION_ITEMS ||--o{ ADHERENCE_LOGS : "prescription_item_id"
    MEDICAL_TESTS ||--o{ PAYMENTS : "test_id"
    AI_CONVERSATIONS ||--o{ AI_MESSAGES : "conversation_id"
    PROFILES ||--o{ AI_CONVERSATIONS : "patient_id"
    PROFILES ||--o{ REVIEWS : "patient_id"
```

---

### 13.6 Class Diagram

```mermaid
classDiagram
    class UserProfile {
        +UUID id
        +UserRole role
        +String fullName
        +String email
        +String phone
        +DateTime dateOfBirth
        +String gender
        +String bloodGroup
        +String avatarUrl
        +EmergencyContact emergencyContact
        +fromJson(json) UserProfile
        +toJson() Map
    }

    class Hospital {
        +UUID id
        +String name
        +String city
        +HospitalStatus status
        +double latitude
        +double longitude
        +double rating
        +approve()
        +reject()
    }

    class Doctor {
        +UUID id
        +UUID profileId
        +UUID hospitalId
        +String specialty
        +List~String~ qualifications
        +double consultationFee
        +double rating
        +DoctorStatus status
        +bool isAvailable
        +bool approvedByHospital
        +approve()
        +reject()
        +setAvailable()
    }

    class DoctorSchedule {
        +UUID id
        +UUID doctorId
        +int dayOfWeek
        +TimeOfDay startTime
        +TimeOfDay endTime
        +int slotDurationMinutes
        +bool isActive
        +getAvailableSlots(date) List~TimeSlot~
    }

    class Appointment {
        +UUID id
        +UUID patientId
        +UUID doctorId
        +UUID hospitalId
        +DateTime appointmentDate
        +TimeOfDay appointmentTime
        +AppointmentStatus status
        +String reason
        +cancel()
        +complete()
        +reschedule(newDate, newTime)
    }

    class MedicalRecord {
        +UUID id
        +UUID patientId
        +UUID doctorId
        +String reportUrl
        +String reportName
        +String diagnosis
        +UUID uploadedBy
        +DateTime createdAt
    }

    class Prescription {
        +UUID id
        +UUID patientId
        +UUID doctorId
        +PrescriptionStatus status
        +List~PrescriptionItem~ items
        +requestRenewal()
    }

    class PrescriptionItem {
        +UUID id
        +UUID prescriptionId
        +String medicationName
        +String dosage
        +String frequency
        +int durationDays
    }

    class AdherenceLog {
        +UUID id
        +UUID prescriptionItemId
        +DateTime scheduledTime
        +AdherenceResponse response
        +DateTime respondedAt
        +getComplianceScore() double
    }

    class AiConversation {
        +UUID id
        +UUID patientId
        +List~AiMessage~ messages
        +sendMessage(text) AiMessage
    }

    class AiMessage {
        +UUID id
        +String role
        +String content
        +DateTime createdAt
    }

    class ConsultationSession {
        +UUID id
        +UUID primaryDoctorId
        +UUID patientId
        +List~UUID~ memberIds
        +sendMessage(text)
        +sharePatientRecord(recordId)
    }

    class Notification {
        +UUID id
        +UUID userId
        +String type
        +String title
        +String body
        +bool isRead
        +markRead()
    }

    class Review {
        +UUID id
        +UUID doctorId
        +UUID patientId
        +int rating
        +String comment
    }

    UserProfile "1" --> "0..*" Appointment : books (patient)
    UserProfile "1" --> "0..*" MedicalRecord : owns
    UserProfile "1" --> "0..*" Prescription : has
    UserProfile "1" --> "0..*" Notification : receives
    Doctor "1" --> "0..*" DoctorSchedule : has
    Doctor "1" --> "0..*" Appointment : attends
    Doctor "1" --> "0..*" Prescription : issues
    Doctor "1" --> "0..*" Review : receives
    Appointment "1" --> "0..1" MedicalRecord : generates
    Prescription "1" --> "1..*" PrescriptionItem : contains
    PrescriptionItem "1" --> "0..*" AdherenceLog : tracked by
    AiConversation "1" --> "1..*" AiMessage : contains
    UserProfile "1" --> "0..*" AiConversation : initiates
    Hospital "1" --> "0..*" Doctor : employs
```

---

### 13.7 Use Case Diagram

```mermaid
flowchart LR
    subgraph Actors
        PA["👑 Platform Admin"]
        HA["🏥 Hospital Admin"]
        R["📋 Receptionist"]
        L["🔬 Lab Staff"]
        PT["👤 Patient"]
        DR["🩺 Doctor"]
    end

    subgraph System["VoxMed Connect — Use Cases"]
        direction TB
        UC1["Register & Login"]
        UC2["Approve / Reject Hospital"]
        UC3["Approve / Reject Doctor\n(Platform Level)"]
        UC4["View Platform Revenue"]
        UC5["Manage Hospital Doctors"]
        UC6["Manage Hospital Staff"]
        UC7["Manage Medical Tests"]
        UC8["View Hospital Profit"]
        UC9["Book Appointment for Patient"]
        UC10["View Doctor Schedules"]
        UC11["Upload Lab Report"]
        UC12["Search Patient Records"]
        UC13["Book Own Appointment"]
        UC14["View Health Passport"]
        UC15["Scan / Upload Medical Records"]
        UC16["Chat with AI Triage Assistant"]
        UC17["Track Medication Adherence"]
        UC18["Request Prescription Renewal"]
        UC19["View Doctor Profile & Reviews"]
        UC20["Manage Schedule"]
        UC21["View Patient Compliance"]
        UC22["Approve Prescription Renewals"]
        UC23["Collaborative Care Session"]
        UC24["Live Consultation + SOAP Notes"]
        UC25["Trigger Emergency Absence"]
    end

    PA --> UC1
    PA --> UC2
    PA --> UC3
    PA --> UC4

    HA --> UC1
    HA --> UC5
    HA --> UC6
    HA --> UC7
    HA --> UC8

    R --> UC1
    R --> UC9
    R --> UC10

    L --> UC1
    L --> UC11
    L --> UC12

    PT --> UC1
    PT --> UC13
    PT --> UC14
    PT --> UC15
    PT --> UC16
    PT --> UC17
    PT --> UC18
    PT --> UC19

    DR --> UC1
    DR --> UC20
    DR --> UC21
    DR --> UC22
    DR --> UC23
    DR --> UC24
    DR --> UC25
```

---

### 13.8 Activity Diagram — Patient Books an Appointment

```mermaid
flowchart TD
    Start([Patient opens Find Care]) --> Search["Search by name / specialty / hospital"]
    Search --> ViewDoctor["View Doctor Profile\n(rating, fee, schedule)"]
    ViewDoctor --> PickDate["Select appointment date"]
    PickDate --> Available{Slot available?}
    Available -- No --> PickDate
    Available -- Yes --> EnterReason["Enter reason for visit"]
    EnterReason --> Confirm["Confirm booking"]
    Confirm --> Insert["INSERT into appointments\n(status = scheduled)"]
    Insert --> Notify["Supabase Realtime pushes\nnotification to Doctor"]
    Notify --> Receipt["Show confirmation screen\nwith appointment details"]
    Receipt --> End([End])
```

---

### 13.9 Activity Diagram — Doctor Approves Prescription Renewal

```mermaid
flowchart TD
    Start([Doctor opens Approval Queue]) --> LoadQueue["Load pending renewal requests\nfrom prescription_renewals"]
    LoadQueue --> SelectRequest["Select a renewal request"]
    SelectRequest --> ViewHistory["View patient adherence history\nand current prescription"]
    ViewHistory --> Decision{Decision}
    Decision -- Approve --> UpdateApproved["UPDATE renewal status = approved\nExtend prescription_items"]
    Decision -- Modify --> EditDosage["Edit dosage / frequency"] --> UpdateApproved
    Decision -- Reject --> UpdateRejected["UPDATE renewal status = rejected"]
    UpdateApproved --> NotifyPatientApproved["Push notification: Renewal Approved"]
    UpdateRejected --> NotifyPatientRejected["Push notification: Renewal Rejected"]
    NotifyPatientApproved --> End([End])
    NotifyPatientRejected --> End
```

---

### 13.10 Sequence Diagram — Patient Books an Appointment

```mermaid
sequenceDiagram
    actor Patient
    participant App as Flutter App
    participant Router as GoRouter
    participant DoctorRepo as DoctorRepository
    participant ApptRepo as AppointmentRepository
    participant Supabase
    participant Doctor as Doctor Device

    Patient->>App: Opens Find Care tab
    App->>DoctorRepo: fetchApprovedDoctors(filters)
    DoctorRepo->>Supabase: SELECT * FROM public_doctors
    Supabase-->>DoctorRepo: Doctor list
    DoctorRepo-->>App: List<Doctor>
    App-->>Patient: Displays doctor cards

    Patient->>App: Taps doctor → booking detail
    App->>DoctorRepo: fetchSchedule(doctorId)
    DoctorRepo->>Supabase: SELECT * FROM doctor_schedules WHERE doctor_id = ?
    Supabase-->>DoctorRepo: Weekly schedule
    DoctorRepo-->>App: List<DoctorSchedule>
    App-->>Patient: Shows available slots

    Patient->>App: Selects date/time, enters reason
    App->>ApptRepo: createAppointment(patientId, doctorId, date, time, reason)
    ApptRepo->>Supabase: INSERT INTO appointments
    Supabase-->>ApptRepo: New appointment row
    ApptRepo-->>App: Appointment created
    App-->>Patient: Shows confirmation screen
    Supabase->>Doctor: Realtime push notification
```

---

### 13.11 Sequence Diagram — OCR Record Upload

```mermaid
sequenceDiagram
    actor Patient
    participant App as Flutter App
    participant StorageRepo as StorageRepository
    participant RecordRepo as MedicalRecordRepository
    participant Supabase
    participant EdgeFn as gemini-ocr\nEdge Function
    participant Gemini as Google Gemini API

    Patient->>App: Taps Scan Records
    App-->>Patient: Camera / Gallery picker
    Patient->>App: Captures / selects image
    App->>StorageRepo: uploadReport(imageFile, patientId)
    StorageRepo->>Supabase: PUT /storage/reports/{filename}
    Supabase-->>StorageRepo: publicUrl
    StorageRepo-->>App: report_url

    App->>RecordRepo: createRecord(patientId, reportUrl)
    RecordRepo->>Supabase: INSERT INTO medical_records
    Supabase-->>RecordRepo: Record ID
    Supabase->>EdgeFn: Trigger on storage.objects INSERT
    EdgeFn->>Gemini: POST /generateContent (image + prompt)
    Gemini-->>EdgeFn: Extracted data (medication, dosage, date)
    EdgeFn->>Supabase: UPDATE medical_records SET diagnosis = extractedData
    RecordRepo-->>App: Record confirmed
    App-->>Patient: Record saved, OCR data shown
```

---

### 13.12 Workflow Diagram (System-wide)

```mermaid
flowchart TD
    A([User opens app/web]) --> B{Authenticated?}
    B -- No --> C[Login Page]
    B -- Yes --> D{Role?}

    C --> E[Submit credentials]
    E --> F[Supabase Auth validates JWT]
    F --> G[Load profiles row]
    G --> D

    D -- patient --> PM[Patient Shell\n4-tab navigation]
    D -- doctor --> DM[Doctor Shell\n3-tab navigation]
    D -- admin --> WA[Web: /admin]
    D -- hospital_admin --> WH[Web: /hospital]
    D -- receptionist --> WR[Web: /receptionist]
    D -- lab_staff --> WL[Web: /lab]
    D -- other --> ERR[Unauthorized page]

    PM --> PM1[Home Dashboard]
    PM --> PM2[Find Care + Booking]
    PM --> PM3[Health Passport]
    PM --> PM4[AI Triage Assistant]

    DM --> DM1[Clinical Dashboard]
    DM --> DM2[Patient List + Compliance]
    DM --> DM3[Prescription Approval Queue]
    DM --> DM4[Live Consultation + SOAP]
    DM --> DM5[Collaborative Care Hub]

    WA --> WA1[Approve Hospitals]
    WA --> WA2[Approve Doctors]
    WA --> WA3[Revenue Dashboard]

    WH --> WH1[Doctor Approval]
    WH --> WH2[Staff Management]
    WH --> WH3[Medical Tests]
    WH --> WH4[Profit Reports]

    WR --> WR1[View Schedules]
    WR --> WR2[Book Appointment]

    WL --> WL1[Find Patient]
    WL --> WL2[Upload Lab Report]
```

---

## 14. Development Phases & Status

| Phase | Description | Status |
|---|---|---|
| 0 | Project setup, design mockups, UI stubs, GoRouter, widgets | ✅ Complete |
| 1 | Foundation & Auth (Supabase init, models, auth screens, Riverpod) | ✅ Complete |
| 2 | Health Passport & Records (MedicalRecord model, scan upload) | 🔄 In Progress |
| 3 | Find Care & Booking (hospital/doctor search, appointment booking) | ✅ Complete |
| 4 | AI Assistant (chat → voice → agentic workflows) | 🔄 In Progress |
| 5 | Prescription & Adherence (renewal flow, adherence tracking) | ⏳ Planned |
| 6 | Doctor Clinical Tools (dashboard, SOAP notes, absence trigger) | ⏳ Planned |
| 7 | Collaborative Care (multi-doctor sessions, Realtime chat) | ⏳ Planned |
| 8 | Web Dashboard (all roles — hospital admin, receptionist, lab, admin) | ✅ Designed |
| 9 | Notifications, Wearable Integration, Performance Hardening | ⏳ Planned |

---

## 15. Screen Inventory

### Flutter Mobile App Screens

| Screen | File | Role |
|---|---|---|
| Login | `auth/login_screen.dart` | All |
| Register | `auth/register_screen.dart` | All |
| Role Selection | `auth/role_selection_screen.dart` | All |
| Patient Dashboard | `dashboard_screen.dart` | Patient |
| Find Care | `find_care_screen.dart` | Patient |
| Doctor Booking Detail | `doctor_booking_detail_screen.dart` | Patient |
| Health Passport | `health_passport_screen.dart` | Patient |
| Health Analytics | `health_analytics_screen.dart` | Patient |
| Scan Records | `scan_records_screen.dart` | Patient |
| Prescription Renewals | `prescription_renewals_screen.dart` | Patient |
| AI Assistant | `ai_assistant_screen.dart` | Patient |
| Profile | `profile_screen.dart` | Patient / Doctor |
| Clinical Dashboard | `clinical_dashboard_screen.dart` | Doctor |
| My Patients | `my_patients_screen.dart` | Doctor |
| Patient Detail | `patient_detail_screen.dart` | Doctor |
| Doctor Chat | `doctor_chat_screen.dart` | Doctor |
| Doctor Schedule | `doctor_schedule_screen.dart` | Doctor |
| Approval Queue | `approval_queue_screen.dart` | Doctor |
| Collaborative Hub | `collaborative_hub_screen.dart` | Doctor |
| Live Consultation | `live_consultation_screen.dart` | Doctor |

### Web Dashboard (HTML Design Prototypes)

| HTML File | Page | Role |
|---|---|---|
| `dashboard.html` | Platform Admin Dashboard | Admin |
| `approval_queue.html` | Approval Queue | Admin / Hospital Admin |
| `clinical_dashboard.html` | Clinical Dashboard | Doctor / Hospital Admin |
| `collaborative_hub.html` | Collaborative Hub | Doctor |
| `ai_assistant.html` | AI Assistant | Patient |
| `find_care_1.html` | Find Care — Hospital List | Patient |
| `find_care_2.html` | Find Care — Doctor List | Patient |
| `doctor_booking_detail.html` | Doctor Booking Detail | Patient |
| `health_analytics.html` | Health Analytics | Patient |
| `health_passport.html` | Health Passport | Patient |
| `live_consultation.html` | Live Consultation | Doctor |

---

*VoxMed Connect — Dual-Platform Healthcare Ecosystem | Flutter + React + Supabase + Google Gemini*
