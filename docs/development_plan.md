# VoxMed Connect — Development Plan

> **Tech Stack:** Flutter + Supabase + Gemini API  
> **Architecture:** REST API Principles with Supabase BaaS  
> **Last Updated:** 2026-03-28

---

## Table of Contents

1. [Architecture Principles](#1-architecture-principles)
2. [Project Structure](#2-project-structure)
3. [API Routing & Data Layer](#3-api-routing--data-layer)
4. [Development Phases](#4-development-phases)
5. [State Management Strategy](#5-state-management-strategy)
6. [Error Handling & Best Practices](#6-error-handling--best-practices)

---

## 1. Architecture Principles

### RESTful Design with Supabase

Supabase exposes a PostgREST API — every table automatically gets RESTful endpoints:

| Operation        | HTTP Method | Supabase Client                                      |
|------------------|-------------|-------------------------------------------------------|
| Read all         | GET         | `supabase.from('table').select()`                     |
| Read one         | GET         | `supabase.from('table').select().eq('id', id).single()` |
| Create           | POST        | `supabase.from('table').insert(data)`                 |
| Update           | PATCH       | `supabase.from('table').update(data).eq('id', id)`    |
| Delete           | DELETE      | `supabase.from('table').delete().eq('id', id)`        |
| Filter/Search    | GET         | `supabase.from('table').select().ilike('name', '%q%')` |

### Key Principles

1. **Thin Client, Smart Backend** — Business logic in Edge Functions; client is a presentation layer
2. **Repository Pattern** — All data access goes through repository classes, never direct Supabase calls from UI
3. **Single Source of Truth** — Supabase Auth JWT determines user identity; RLS enforces data boundaries
4. **Separation of Concerns** — `models/`, `repositories/`, `providers/`, `screens/`, `widgets/` are distinct layers
5. **Realtime-First** — Use Supabase Realtime subscriptions where live data matters (appointments, chat, notifications)

---

## 2. Project Structure

```
lib/
├── main.dart                          # App entry, Supabase init
├── core/
│   ├── config/
│   │   └── supabase_config.dart       # Supabase client singleton
│   ├── constants/
│   │   └── app_constants.dart         # Route paths, API keys ref, enums
│   ├── router/
│   │   └── app_router.dart            # GoRouter config (already exists)
│   ├── theme/
│   │   ├── app_colors.dart            # (already exists)
│   │   └── app_theme.dart             # (already exists)
│   └── utils/
│       ├── extensions.dart            # DateTime, String extensions
│       ├── validators.dart            # Form validation helpers
│       └── error_handler.dart         # Centralized error handling
│
├── models/                            # Data models (fromJson/toJson)
│   ├── user_profile.dart
│   ├── hospital.dart
│   ├── doctor.dart
│   ├── doctor_schedule.dart
│   ├── appointment.dart
│   ├── medical_record.dart
│   ├── prescription.dart
│   ├── prescription_item.dart
│   ├── prescription_renewal.dart
│   ├── adherence_log.dart
│   ├── ai_conversation.dart
│   ├── ai_message.dart
│   ├── consultation_session.dart
│   ├── notification_model.dart
│   ├── review.dart
│   └── wearable_data.dart
│
├── repositories/                      # Data access layer (Supabase calls)
│   ├── auth_repository.dart
│   ├── profile_repository.dart
│   ├── hospital_repository.dart
│   ├── doctor_repository.dart
│   ├── appointment_repository.dart
│   ├── medical_record_repository.dart
│   ├── prescription_repository.dart
│   ├── adherence_repository.dart
│   ├── ai_repository.dart
│   ├── consultation_repository.dart
│   ├── notification_repository.dart
│   ├── review_repository.dart
│   └── storage_repository.dart
│
├── providers/                         # State management (Riverpod)
│   ├── auth_provider.dart
│   ├── profile_provider.dart
│   ├── hospital_provider.dart
│   ├── doctor_provider.dart
│   ├── appointment_provider.dart
│   ├── medical_record_provider.dart
│   ├── prescription_provider.dart
│   ├── adherence_provider.dart
│   ├── ai_provider.dart
│   ├── consultation_provider.dart
│   └── notification_provider.dart
│
├── screens/                           # UI screens (already has mockups)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── role_selection_screen.dart
│   ├── patient/
│   │   ├── dashboard_screen.dart
│   │   ├── find_care_screen.dart
│   │   ├── doctor_booking_detail_screen.dart
│   │   ├── health_passport_screen.dart
│   │   ├── health_analytics_screen.dart
│   │   ├── scan_records_screen.dart
│   │   ├── prescription_renewals_screen.dart
│   │   └── ai_assistant_screen.dart
│   └── doctor/
│       ├── clinical_dashboard_screen.dart
│       ├── approval_queue_screen.dart
│       ├── collaborative_hub_screen.dart
│       └── live_consultation_screen.dart
│
└── widgets/                           # Reusable components
    ├── voxmed_app_bar.dart            # (already exists)
    ├── voxmed_bottom_nav.dart         # (already exists)
    ├── voxmed_card.dart               # (already exists)
    ├── ai_fab.dart                    # (already exists)
    ├── loading_indicator.dart
    ├── error_widget.dart
    └── empty_state_widget.dart
```

---

## 3. API Routing & Data Layer

### Authentication Flow

```
Sign Up → Supabase Auth (email+password, role in metadata)
       → Trigger: handle_new_user() creates profiles row
       → Client receives JWT with user.id
       → App checks profiles.role → routes to Patient or Doctor shell
```

### API Endpoints via Supabase PostgREST

| Domain          | Table(s)                                  | Key Operations                                          |
|-----------------|-------------------------------------------|---------------------------------------------------------|
| **Auth**        | `auth.users`, `profiles`                  | signUp, signIn, signOut, getProfile, updateProfile      |
| **Hospitals**   | `hospitals`                               | list, getById, search by city/name                      |
| **Doctors**     | `doctors`, `doctor_schedules`             | list, filter by specialty/hospital, getSchedule         |
| **Appointments**| `appointments`                            | create, cancel, reschedule, listByPatient, listByDoctor |
| **Records**     | `medical_records`                         | create, list, OCR upload (Edge Function)                |
| **Prescriptions**| `prescriptions`, `prescription_items`, `prescription_renewals` | create, list, requestRenewal, approveRenewal |
| **Adherence**   | `adherence_logs`                          | log, getComplianceScore, listByPatient                  |
| **AI Triage**   | `ai_conversations`, `ai_messages`         | createConversation, sendMessage (Edge Function)         |
| **Consultations**| `consultation_sessions`, `consultation_members`, `consultation_messages` | create, invite, sendMessage (Realtime) |
| **Notifications**| `notifications`                          | list, markRead, subscribe (Realtime)                    |
| **Reviews**     | `reviews`                                 | create, listByDoctor                                    |
| **Storage**     | Supabase Storage                          | uploadAvatar, uploadReport, uploadPrescriptionImage     |

### Edge Functions (Serverless)

| Function              | Trigger                | Purpose                                              |
|-----------------------|------------------------|------------------------------------------------------|
| `gemini-ocr`          | Report upload          | Extract structured data from prescription images     |
| `gemini-triage`       | AI chat message        | Process symptom description, return triage result     |
| `auto-reschedule`     | Doctor absence created | Find next available slot, update appointments, notify |
| `soap-notes`          | Consultation ended     | Generate SOAP note from transcription                |
| `medication-reminder` | Cron (scheduled)       | Check adherence schedule, send push notifications    |

---

## 4. Development Phases

### Phase 1: Foundation & Auth (Week 1-2)

**Goal:** Project setup, auth flow, role-based routing

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Integrate `supabase_flutter`, init client in `main.dart`    | P0       |
| 2 | Run database migration (enums, tables, indexes, RLS, triggers) | P0    |
| 3 | Create `models/` for `UserProfile`, `Doctor`, `Hospital`    | P0       |
| 4 | Build `AuthRepository` (signUp, signIn, signOut, getSession)| P0       |
| 5 | Build Login, Register, Role Selection screens               | P0       |
| 6 | Update `AppRouter` for auth guard + role-based routing      | P0       |
| 7 | Add `flutter_riverpod` for state management                 | P0       |
| 8 | Create storage buckets (avatars, reports, prescriptions)    | P1       |

**Deliverable:** Users can sign up as Patient or Doctor and land on their respective dashboards.

---

### Phase 2: Patient Core — Health Passport & Records (Week 3-4)

**Goal:** Digital health passport, medical records, document scanning

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Build `MedicalRecordRepository` & `MedicalRecord` model    | P0       |
| 2 | Health Passport screen — list prescriptions, lab results    | P0       |
| 3 | Scan Records screen — camera capture + upload to Storage    | P0       |
| 4 | Deploy `gemini-ocr` Edge Function for data extraction       | P1       |
| 5 | Profile editing (avatar upload, personal info)              | P1       |
| 6 | Display extracted OCR data in Health Passport               | P1       |

**Deliverable:** Patients can view their health passport, upload/scan reports, and see OCR-extracted data.

---

### Phase 3: Find Care & Booking (Week 5-6)

**Goal:** Hospital/doctor directory, search, appointment booking

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Build `HospitalRepository`, `DoctorRepository`             | P0       |
| 2 | Find Care screen — search hospitals, filter doctors by specialty | P0  |
| 3 | Doctor Booking Detail screen — view profile, schedule, fees | P0       |
| 4 | `AppointmentRepository` — create, cancel, list              | P0       |
| 5 | Doctor schedule slots — show available times                | P0       |
| 6 | Patient dashboard — upcoming appointments widget            | P1       |
| 7 | Reviews system — post-appointment reviews                   | P2       |

**Deliverable:** Patients can search for care, view doctor profiles, and book appointments.

---

### Phase 4: AI Triage Assistant (Week 7-8)

**Goal:** Conversational AI for symptom triage and doctor suggestions

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Deploy `gemini-triage` Edge Function                        | P0       |
| 2 | Build `AiRepository` (create conversation, send message)    | P0       |
| 3 | AI Assistant screen — chat UI with bubble messages          | P0       |
| 4 | Triage result → suggested specialty + doctor list           | P0       |
| 5 | Connect triage output to Find Care (deep link to doctors)   | P1       |
| 6 | Conversation history & past triages                         | P2       |

**Deliverable:** Patients can describe symptoms, get AI triage, and be directed to the right doctor.

---

### Phase 5: Prescriptions & Adherence (Week 9-10)

**Goal:** Prescription management, medication tracking, renewal workflow

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Build `PrescriptionRepository` + models                    | P0       |
| 2 | Prescription Renewals screen (patient side)                 | P0       |
| 3 | Adherence logging — scheduled reminders                     | P0       |
| 4 | Deploy `medication-reminder` Edge Function (cron)          | P1       |
| 5 | Compliance score calculation                                | P1       |
| 6 | Renewal request → Doctor approval queue flow                | P0       |
| 7 | Voice-based adherence tracking (basic — Phase 2+)          | P2       |

**Deliverable:** Full prescription lifecycle from issuance to renewal with medication reminders.

---

### Phase 6: Doctor Dashboard & Clinical Tools (Week 11-13)

**Goal:** Doctor-side features — schedule management, patient views, approvals

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Clinical Dashboard — today's patients, compliance scores    | P0       |
| 2 | Doctor schedule management (create/update slots)            | P0       |
| 3 | Approval Queue screen — pending renewal requests            | P0       |
| 4 | Patient profile view (from doctor's perspective)            | P0       |
| 5 | Emergency Absence trigger + `auto-reschedule` Edge Function| P1       |
| 6 | Patient medication & record history view                    | P1       |

**Deliverable:** Doctors can manage their schedule, view patients, and process prescription renewals.

---

### Phase 7: Collaborative Care & Realtime (Week 14-15)

**Goal:** Multi-doctor collaboration, real-time messaging

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Build `ConsultationRepository` (Realtime subscriptions)    | P0       |
| 2 | Collaborative Hub screen — invite specialists, share data   | P0       |
| 3 | Realtime chat within consultation sessions                  | P0       |
| 4 | Shared patient record view for session members              | P1       |
| 5 | Push notifications integration                              | P1       |

**Deliverable:** Doctors can collaborate on patient cases with real-time updates.

---

### Phase 8: Health Analytics & Wearables (Week 16-17)

**Goal:** Health data visualization, wearable integration prep

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | Health Analytics screen — medication adherence charts       | P0       |
| 2 | Blood pressure / vitals trend visualization                 | P0       |
| 3 | Compliance score over time (from adherence_logs)            | P1       |
| 4 | Wearable data model + placeholder integration               | P2       |
| 5 | Health Pulse widget on patient dashboard                    | P1       |

**Deliverable:** Patients see visual health trends; wearable integration is scaffolded.

---

### Phase 9: Polish, Testing & Launch Prep (Week 18-20)

| # | Task                                                        | Priority |
|---|-------------------------------------------------------------|----------|
| 1 | End-to-end testing (auth flows, booking, prescriptions)     | P0       |
| 2 | Error handling and edge cases                                | P0       |
| 3 | Loading states, empty states, skeleton loaders              | P1       |
| 4 | Performance optimization (lazy loading, caching)            | P1       |
| 5 | App icon, splash screen, app store metadata                 | P1       |
| 6 | Security audit (RLS policies, API key exposure)             | P0       |

---

### Future Phases (Post-Launch)

| Feature                      | Phase  |
|------------------------------|--------|
| Voice-based adherence tracking (ElevenLabs) | Phase 2+ |
| Live video consultation      | Phase 2+ |
| SOAP notes (ambient transcription) | Phase 2+ |
| Wearable device sync (Oura, Apple Watch) | Phase 2+ |
| Duolingo-style AI engagement | Phase 3+ |
| Multi-language support       | Phase 3+ |

---

## 5. State Management Strategy

Using **Riverpod** for state management:

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  UI Screen   │────▶│   Provider    │────▶│  Repository  │
│  (Widget)    │◀────│   (Notifier)  │◀────│  (Supabase)  │
└─────────────┘     └──────────────┘     └─────────────┘
```

| Layer       | Responsibility                                    | Example                          |
|-------------|---------------------------------------------------|----------------------------------|
| Screen      | Renders UI, reads providers, dispatches actions   | `DashboardScreen`                |
| Provider    | Holds state, orchestrates business logic           | `appointmentProvider`            |
| Repository  | Executes Supabase queries, returns typed models   | `AppointmentRepository.list()`   |
| Model       | Data class with `fromJson` / `toJson`              | `Appointment`                    |

---

## 6. Error Handling & Best Practices

### Error Handling
```dart
// Repository level — catch and rethrow typed exceptions
try {
  final response = await supabase.from('appointments').select();
  return response.map((e) => Appointment.fromJson(e)).toList();
} on PostgrestException catch (e) {
  throw AppException(message: e.message, code: e.code);
} catch (e) {
  throw AppException(message: 'Unexpected error');
}
```

### Best Practices Checklist

- [ ] **Never** expose `service_role_key` in client code — use Edge Functions
- [ ] **Always** use RLS — never disable for convenience
- [ ] **Always** validate input on both client and server (Edge Functions)
- [ ] **Use** `select('column1, column2')` instead of `select('*')` for performance
- [ ] **Use** Supabase Realtime only where needed (appointments, chat, notifications)
- [ ] **Cache** hospital/doctor lists locally with TTL
- [ ] **Paginate** all list queries (`.range(from, to)`)
- [ ] **Log** errors to a monitoring service in production
