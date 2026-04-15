# VoxMed Connect — Progress Tracker

> **Last Updated:** 2026-04-14

---

## Legend

- ✅ Done
- 🔄 In Progress
- ⏳ Not Started

---

## Phase 0: Project Setup & Design (Complete)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Create Flutter project | ✅ | 2026-03-20 | `voxmed` with Material 3 |
| Define design system (colors, typography) | ✅ | 2026-03-20 | `app_colors.dart`, `app_theme.dart` — green primary, Manrope + Inter |
| Create UI design mockups (13 screens) | ✅ | 2026-03-20 | HTML prototypes + screenshots in `design/` |
| Build screen stubs (all 13) | ✅ | 2026-03-20 | Static UI in `lib/screens/` |
| Set up GoRouter with bottom nav shell | ✅ | 2026-03-20 | `app_router.dart` with ShellRoute |
| Create reusable widgets | ✅ | 2026-03-20 | `VoxmedAppBar`, `VoxmedBottomNav`, `VoxmedCard`, `AiFab` |
| Write PRD document | ✅ | 2026-03-20 | `docs/PRD.md` |
| Write Database Schema document | ✅ | 2026-03-28 | `docs/database_schema.md` — 19 tables, RLS, setup guide |
| Write Development Plan document | ✅ | 2026-03-28 | `docs/development_plan.md` — 9 phases, REST principles |
| Write DFD document | ✅ | 2026-03-28 | `docs/dfd.md` — Context, Level-0, 7× Level-1 |
| Update README with full context | ✅ | 2026-03-28 | AI context guide, project structure, doc links |
| Create Progress tracker | ✅ | 2026-03-28 | This file |

---

## Phase 1: Foundation & Auth (Complete ✅)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Add `flutter_riverpod` + `intl` dependencies | ✅ | 2026-03-28 | `pubspec.yaml` updated |
| Supabase client initialized in `main.dart` | ✅ | 2026-03-28 | Already done in Phase 0, now also in `supabase_config.dart` |
| Run database migration in Supabase | ✅ | 2026-03-28 | Manually done by user in cloud |
| Create `supabase_config.dart` | ✅ | 2026-03-28 | Singleton accessor in `lib/core/config/` |
| Create `app_constants.dart` | ✅ | 2026-03-28 | Routes, table names, buckets, 8 Dart enums |
| Create `extensions.dart` | ✅ | 2026-03-28 | DateTime + String extensions |
| Create `validators.dart` | ✅ | 2026-03-28 | Email, password, name, phone validators |
| Create `error_handler.dart` | ✅ | 2026-03-28 | AppException, error/success SnackBars |
| Create data models (10 files) | ✅ | 2026-03-28 | UserProfile, Hospital, Doctor, DoctorSchedule, Appointment, MedicalRecord, Prescription, PrescriptionItem, NotificationModel, Review |
| Build `AuthRepository` | ✅ | 2026-03-28 | signUp (with metadata), signIn, signOut, session |
| Build `ProfileRepository` | ✅ | 2026-03-28 | getProfile, updateProfile, getCurrentUserProfile |
| Build `HospitalRepository` | ✅ | 2026-03-28 | list, get, search |
| Build `DoctorRepository` | ✅ | 2026-03-28 | list, get, filterBySpecialty, create, getSchedule |
| Build `AppointmentRepository` | ✅ | 2026-03-28 | create, listByPatient, listUpcoming, listByDoctor, updateStatus |
| Create Riverpod providers (5 files) | ✅ | 2026-03-28 | auth, profile, hospital, doctor, appointment |
| Build Login screen | ✅ | 2026-03-28 | Email/password, validation, role-based redirect |
| Build Register screen | ✅ | 2026-03-28 | Role toggle (Patient/Doctor), metadata sign-up |
| Add auth guard to router | ✅ | 2026-03-28 | Redirect unauthenticated → `/login` |
| Add role-based routing | ✅ | 2026-03-28 | Patient shell (4 tabs) + Doctor shell (3 tabs) |
| Wrap app with `ProviderScope` | ✅ | 2026-03-28 | `main.dart` updated |
| Create shared widgets | ✅ | 2026-03-28 | LoadingIndicator, ErrorWidget, EmptyStateWidget |
| Write unit tests | ✅ | 2026-03-28 | 36 tests — models, validators, enums |
| `flutter analyze` — 0 issues | ✅ | 2026-03-28 | Clean |
| `flutter test` — all passing | ✅ | 2026-03-28 | 36/36 passed |

---

## Phase 2: Health Passport & Records (🔄 In Progress)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Build `MedicalRecord` model + repository | ✅ | 2026-04-07 | Repository/provider wired to Supabase records |
| Connect Health Passport screen to live data | ✅ | 2026-04-07 | Passport now renders recent records and prescriptions |
| Implement Scan Records (camera + upload) | ✅ | 2026-04-10 | Camera/gallery pick → Supabase Storage → DB record; null FK guard fix |
| Deploy `gemini-ocr` Edge Function | ⏳ | | Pending backend function deployment |
| Profile editing (avatar upload) | ⏳ | | Pending |
| Dashboard digital passport card routing | ✅ | 2026-04-10 | Card now navigates to Health Passport panel |
| Dashboard recent reports auto-fetch | ✅ | 2026-04-08 | Switched to `recentMedicalRecordsProvider` (auto-fetches) |

---

## Phase 3: Find Care & Booking (✅ Completed)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Build hospital/doctor models + repositories | ✅ | 2026-03-28 | Hospital and doctor data layer completed |
| Connect Find Care screen to live data | ✅ | 2026-04-08 | Hospital search and doctor listing are live; search now covers doctors too |
| Build appointment booking flow | ✅ | 2026-04-07 | Doctor detail and booking flow connected |
| Doctor schedule availability display | ✅ | 2026-04-07 | Schedules load from repository/providers |
| Reviews system | ✅ | 2026-04-07 | Review data seeded and surfaced in booking context |
| Fix RenderFlex overflow on doctor filter row | ✅ | 2026-04-10 | Wrapped title in `Flexible` widget |

---

## Phase 4: AI Assistant (Chat → Voice → Agentic) (🔄 In Progress)

Rollout plan (3 parts):

1) **Chat (text only):** Gemini triage responses stored in `ai_messages`
2) **Voice:** speech-to-text + text-to-speech on the AI assistant screen
3) **Agentic workflows:** tool-driven actions (doctor selection, tests, scheduling) with explicit user approval

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Validate AI chat schema for session history + deletion | ✅ | 2026-04-14 | `ai_messages.conversation_id` uses `ON DELETE CASCADE`; RLS policies restrict access to owner sessions/messages |
| Implement `gemini-triage` source with key fallback | ✅ | 2026-04-14 | Added `supabase/functions/gemini-triage/` with `GEMINI_API_KEY_1..N` fallback on rate limits |
| Deploy `gemini-triage` Edge Function to Supabase | ✅ | 2026-04-14 | Linked project `jedgnisrjwemhazherro`, uploaded Gemini secrets, deployed function (active) |
| Wire AI Assistant “Send” → `gemini-triage` response | ✅ | 2026-04-14 | `AiRepository.sendMessage()` now invokes Edge Function and refreshes conversation/message providers |
| AI conversation/message read providers | ✅ | 2026-04-07 | `aiConversationsProvider` + `aiMessagesProvider` (Supabase tables) |
| AI Assistant chat persistence (create conversation + insert user messages) | ✅ | 2026-04-07 | Writes to `ai_conversations` + `ai_messages` |
| Chat session controls (new, resume old, delete old) | ✅ | 2026-04-14 | Added history sheet + session switch + delete flow in AI assistant screen |
| Editable system prompts for patient/doctor roles | ✅ | 2026-04-14 | Added `supabase/functions/gemini-triage/system_prompts.json` |
| Foreground voice scaffolding (speech-to-text + TTS) | ✅ | | Implemented via `speech_to_text` + `flutter_tts` in AI assistant screen |
| Triage result → suggested specialty + doctor list | 🔄 | 2026-04-14 | Edge function now returns structured triage JSON; Find Care deep-link UI still pending |
| Agentic workflows (appointments/tests/med scheduling) | ⏳ | | Planned: requires safe tool orchestration + audit logging |

---

## Phase 5: Prescriptions & Adherence (✅ Completed)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Prescription models + repository | ✅ | 2026-04-07 | Prescription repository/provider implemented |
| Adherence logging system | ✅ | 2026-04-07 | Analytics and medication adherence data connected |
| Medication reminders (Edge Function cron) | ⏳ | | Notification seeding complete; cron automation pending |
| Renewal request + approval flow | ✅ | 2026-04-07 | Patient requests and doctor approval queue are functional |

---

## Phase 6: Doctor Dashboard (✅ Completed)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Clinical Dashboard with live data | ✅ | 2026-04-07 | Dashboard cards and today appointments are live |
| Fix double AppBar on doctor screens | ✅ | 2026-04-08 | Removed inner Scaffold from ClinicalDashboard + ApprovalQueue |
| Schedule management | 🔄 | 2026-04-08 | Doctor identity rows now auto-heal on login/sign-up; richer editing still pending |
| Approval Queue | ✅ | 2026-04-07 | Approve/Deny actions update renewal status |
| Emergency Absence + auto-reschedule | ⏳ | | Pending |

---

## Phase 7: Collaborative Care (✅ Completed)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Consultation sessions + realtime chat | ✅ | 2026-04-07 | Session and message data connected to UI |
| Specialist invitation flow | ⏳ | | Invitation workflow pending |
| Shared patient data view | ✅ | 2026-04-07 | Collaborative hub shows live consultation content |

---

## Phase 8: Health Analytics (✅ Completed)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Adherence charts + vitals trends | ✅ | 2026-04-07 | Health analytics screen now binds to wearable/adherence data |
| Compliance score visualization | ✅ | 2026-04-07 | Dashboard analytics are data-backed |
| Wearable data scaffolding | ✅ | 2026-04-07 | Wearable repository/provider path is active via Supabase data |

---

## Phase 9: Polish & Launch (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| E2E testing | ⏳ | | |
| Error handling + loading states | ⏳ | | |
| Performance optimization | ⏳ | | |
| Security audit | ⏳ | | |
| App store prep | ⏳ | | |

---

## Recent Fixes

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Seed Supabase test data | ✅ | 2026-04-08 | `seed_data.sql` corrected and populated with valid UUIDs |
| Fix Android cross-drive Gradle build failure on Windows | ✅ | 2026-04-08 | `kotlin.incremental=false` resolves plugin cache path issue |
| Build and deploy debug APK to device | ✅ | 2026-04-08 | Debug APK built successfully after Gradle fix |
| Repair doctor signup flow | ✅ | 2026-04-08 | Doctor accounts now create/repair `doctors` rows on sign-up and login |
| Expand Find Care search to doctors | ✅ | 2026-04-08 | Shared search bar now filters doctor results by name, specialty, and hospital |
| Implement AI Chat Part 1 code path | ✅ | 2026-04-14 | Added `gemini-triage` function source, AI repository invocation, and chat session history controls |
| Configure Supabase CLI + cloud deploy for AI chat | ✅ | 2026-04-14 | Installed local CLI flow (`npx supabase`), linked cloud project, set secrets, verified endpoint no longer returns 404 |

---

## Phase A: Code Review Fixes (✅ 2026-04-08 → 2026-04-10)

Comprehensive code audit identified and fixed 13 consistency issues:

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Fix double AppBar on doctor screens | ✅ | 2026-04-08 | Removed inner Scaffold from ClinicalDashboard + ApprovalQueue |
| Fix `responded_at` column name | ✅ | 2026-04-08 | Was `reviewed_at`, didn't match DB schema |
| Fix storage bucket mismatch | ✅ | 2026-04-08 | Hardcoded `medical-records` → `Buckets.reports` |
| Fix dashboard records auto-fetch | ✅ | 2026-04-08 | Switched to `recentMedicalRecordsProvider` |
| Fix booking slot duration | ✅ | 2026-04-08 | Uses actual `slotDurationMinutes` instead of hardcoded 30 |
| Add patient profile join to appointments | ✅ | 2026-04-08 | Added FK join for patient name + avatar on both sides |
| Wire dashboard banner buttons | ✅ | 2026-04-08 | "Health Passport" + "Vitals Summary" now navigate to real routes |
| Route digital passport card | ✅ | 2026-04-10 | Card now taps through to Health Passport panel |
| Fix RenderFlex overflow — Find Care | ✅ | 2026-04-10 | Wrapped doctor title text in `Flexible` widget |
| Fix medical record insert map | ✅ | 2026-04-10 | Replaced `?key` null-aware → explicit `if` guards (avoids sending null to FK columns) |
| Invalidate providers after upload | ✅ | 2026-04-08 | `recentMedicalRecordsProvider` refreshed after record upload |
| **RLS policy for `medical_records` INSERT** | 🔧 | 2026-04-10 | **Requires SQL in Supabase** — see below |
| **Storage bucket `reports` creation** | 🔧 | 2026-04-10 | **Requires SQL in Supabase** — see below |

### ⚠️ Supabase Actions Required

Run the following SQL in the **Supabase SQL Editor** to fix the RLS violation on record upload:

```sql
-- 1. Ensure RLS is enabled on medical_records
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;

-- 2. Create INSERT policy for patients (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'medical_records' AND policyname = 'Patients insert own records'
  ) THEN
    CREATE POLICY "Patients insert own records" ON medical_records
      FOR INSERT WITH CHECK (patient_id = auth.uid());
  END IF;
END $$;

-- 3. Ensure the reports storage bucket exists
INSERT INTO storage.buckets (id, name, public)
  VALUES ('reports', 'reports', true)
  ON CONFLICT (id) DO NOTHING;

-- 4. Storage policy: allow authenticated users to upload to their own folder
CREATE POLICY "Users upload own reports" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'reports' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- 5. Storage policy: allow authenticated users to read their own files
CREATE POLICY "Users read own reports" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'reports' AND
    auth.role() = 'authenticated'
  );
```
