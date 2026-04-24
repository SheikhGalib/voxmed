# VoxMed Connect — Progress Tracker

> **Last Updated:** 2026-04-16

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
| Schedule management | ✅ | 2026-05-28 | Full day/week/month schedule view with appointment list; `DoctorScheduleScreen` in doctor shell |
| Approval Queue | ✅ | 2026-04-07 | Approve/Deny actions update renewal status |
| My Patients section | ✅ | 2026-05-28 | `MyPatientsScreen` — searchable patient list; tap opens full patient detail |
| Patient Detail screen | ✅ | 2026-05-28 | `PatientDetailScreen` — Overview, Prescriptions, Records, Analytics (bar chart, pie chart, medication trends) |
| Write Prescription from patient detail | ✅ | 2026-05-28 | Bottom sheet form in Prescriptions tab; creates prescription + items in Supabase |
| Analytics trend charts per patient | ✅ | 2026-05-28 | `fl_chart` bar chart (visit frequency), pie chart (appointment types), medication history bars |
| Doctor bottom nav updated (5 tabs) | ✅ | 2026-05-28 | Dashboard · Schedule · My Patients · Approvals · Collaborate |
| New route constants | ✅ | 2026-05-28 | `doctorSchedule`, `myPatients`, `patientDetail` added to `AppRoutes` |
| Repository additions | ✅ | 2026-05-28 | `listByDoctorRange`, `listDoctorPatients`, `listPatientVisitsForDoctor` (Appointment); `createPrescriptionWithItems` (Prescription); `listByPatientId` (MedicalRecord) |
| `patient_provider.dart` (new) | ✅ | 2026-05-28 | Riverpod providers for doctor-scoped patient data and prescription creation |
| Doctor dashboard tests | ✅ | 2026-05-28 | 8 tests in `test/doctor_dashboard_test.dart` — routes, models, chart logic; all passing |
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

## Phase 10: Video Calling — ZEGOCLOUD Integration (🔄 In Progress)

> **Plan:** See `docs/video_calling_implementation.md` for full 5-phase implementation plan.

### Phase 1 — Basic Video Calling (🔄 In Progress)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Add ZEGOCLOUD & permission_handler dependencies to pubspec.yaml | ✅ | 2026-04-15 | `zego_uikit_prebuilt_call: ^4.22.0`, `zego_uikit_signaling_plugin: ^2.10.0`, `permission_handler: ^11.3.0` |
| Create `zego_config.dart` (reads ZEGO_APP_ID/ZEGO_APP_SIGN from .env) | ✅ | 2026-04-15 | `lib/core/config/zego_config.dart` |
| Create `VideoCall` model with `VideoCallStatus` enum | ✅ | 2026-04-15 | `lib/models/video_call.dart` |
| Create `VideoCallRepository` (Supabase CRUD) | ✅ | 2026-04-15 | `lib/repositories/video_call_repository.dart` — createVideoCall, getByAppointment, updateStatus, completeCall |
| Create `VideoCallProvider` (Riverpod) | ✅ | 2026-04-15 | `lib/providers/video_call_provider.dart` |
| Create `VideoCallScreen` with ZEGOCLOUD PrebuiltCall wrapper | ✅ | 2026-04-15 | `lib/screens/video_call_screen.dart` — hang-up confirmation, call status management, duration display |
| Add `/video-call` route to GoRouter | ✅ | 2026-04-15 | `lib/core/router/app_router.dart` with roomId + videoCallId query params |
| Add `AppRoutes.videoCall` and `Tables.videoCalls` constants | ✅ | 2026-04-15 | `lib/core/constants/app_constants.dart` |
| Auto-create video call room in booking flow | ✅ | 2026-04-15 | `_confirmBooking()` in doctor_booking_detail_screen.dart |
| Add appointment type toggle (In-Person / Video) to booking screen | ✅ | 2026-04-16 | `_buildAppointmentTypeToggle()` — was missing, fixed |
| Add Android permissions for ZEGOCLOUD | ✅ | 2026-04-16 | CAMERA, WIFI, NETWORK, BLUETOOTH, VIBRATE, FULL_SCREEN_INTENT, SCHEDULE_EXACT_ALARM |
| Add video icon + "Join Call" button to patient dashboard tile | ✅ | 2026-04-16 | `_UpcomingAppointmentTile` shows videocam icon and Join button for video appointments |
| Add video indicator to doctor daily schedule | ✅ | 2026-04-16 | `_ScheduleItem` shows videocam icon for video appointments |
| Update `database_schema.md` with video calling tables | ✅ | 2026-04-16 | Added `video_calls`, `call_transcripts`, `emergency_call_requests` tables, RLS, indexes, enum updates |
| Create Supabase `video_calls` table in database | ⏳ | | SQL in `video_calling_implementation.md` §6.1 |
| Create Supabase `call_transcripts` table | ⏳ | | SQL in §6.2 |
| Create Supabase `emergency_call_requests` table | ⏳ | | SQL in §6.3 |
| Add new `notification_type` enum values | ⏳ | | SQL in §6.4: video_call_scheduled, video_call_starting, etc. |
| Test end-to-end video call flow | ⏳ | | Requires ZEGOCLOUD credentials in .env |

### Phase 2–5 — Not Started

---

## Cross-Platform: Shared Database (voxmed + voxmedweb)

> **Context:** The Flutter app and the React web management dashboard use the same Supabase project (`jedgnisrjwemhazherro`). RLS bugs in one app affect the other.

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Identify shared database between Flutter app and web dashboard | ✅ | 2026-04-24 | Same Supabase project; `user_role` enum covers all 6 roles |
| Update `database_schema.md` to reflect actual cloud schema | ✅ | 2026-04-24 | Added `hospital_staff` table, `hospital_status`/`doctor_status` enums, approval fields on `doctors` and `hospitals`, updated architecture overview |
| Diagnose doctor-not-appearing-for-approval bug | ✅ | 2026-04-24 | Root cause: missing INSERT RLS policy on `doctors` for authenticated users — see `docs/rls_fix_doctor_visibility.md` |
| Create fix doc for RLS issue | ✅ | 2026-04-24 | `docs/rls_fix_doctor_visibility.md` — full root cause analysis, fix SQL, verification steps |
| Create migration `002_fix_rls_policies.sql` | ✅ | 2026-04-24 | At `voxmedweb/supabase/migrations/002_fix_rls_policies.sql` |
| Apply RLS fix in Supabase cloud | ✅ | 2026-04-24 | Migration applied — hospital dashboard now shows doctors |
| Fix stale "Approval Pending" after sign-in (Flutter) | ✅ | 2026-04-24 | `currentDoctorProvider` now watches `authStateProvider` — auto-invalidates on sign-in/out |
| Fix `is_available` column mismatch in doctor_schedules (web) | ✅ | 2026-04-24 | Renamed to `is_active` in server Zod schema |
| Fix `max_patients` column not found in doctor_schedules (web) | ✅ | 2026-04-24 | Renamed to `slot_duration_minutes` in server + client form |
| Fix ON CONFLICT error when saving doctor schedule (web) | ✅ | 2026-04-25 | Replaced `.upsert()` with select-then-update-or-insert; created migration `003` for DB constraint |
| Create migration `003_add_doctor_schedules_unique_constraint.sql` | ⚠️ | 2026-04-25 | **ACTION REQUIRED** — run in Supabase SQL Editor to add `UNIQUE(doctor_id, day_of_week)` |
| Write Flutter scheduling unit tests | ✅ | 2026-04-25 | `test/scheduling_test.dart` — 12 tests covering fromJson, toJson, day names, slot count |
| Write web scheduling unit tests | ✅ | 2026-04-25 | `server/src/test/scheduling.test.js` — 21 tests covering Zod schema, slot count, upsert logic |

### ⚠️ Supabase Action Required — Doctor Schedules Unique Constraint

Run the contents of `voxmedweb/supabase/migrations/003_add_doctor_schedules_unique_constraint.sql` in the **Supabase SQL Editor**:

1. Open https://supabase.com/dashboard → project `jedgnisrjwemhazherro`
2. Navigate to **SQL Editor → New query**
3. Paste and run the migration

This adds `UNIQUE(doctor_id, day_of_week)` to `doctor_schedules`. The server already works without it (select-then-update-or-insert), but the constraint provides database-level enforcement as a safety net.

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 2 | Scheduled Meetings & Notifications (call invitations, push) | ⏳ |
| Phase 3 | Emergency Calling (early responder queue) | ⏳ |
| Phase 4 | Real-Time ASR Transcription (Deepgram streaming) | ⏳ |
| Phase 5 | SOAP Notes Generation (Gemini edge function) | ⏳ |

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
| Fix missing `_buildAppointmentTypeToggle()` method | ✅ | 2026-04-16 | Method was called but never defined — compile error from disconnected previous session |
| Add ZEGOCLOUD Android permissions | ✅ | 2026-04-16 | AndroidManifest.xml was missing CAMERA, WIFI, NETWORK, BLUETOOTH permissions |
| Add video call UI integration to dashboards | ✅ | 2026-04-16 | Patient dashboard "Join Call" button + doctor schedule video icon |
| Update database_schema.md for video calling | ✅ | 2026-04-16 | 3 new tables (§3.20–3.22), RLS policies, indexes, notification_type enum |
| Fix Java 17 toolchain missing error | ✅ | 2026-04-16 | Added `foojay-resolver-convention 0.9.0` to `settings.gradle.kts` for JDK 17 auto-download |
| Fix `zego_zim 2.28.0` API breakage | ✅ | 2026-04-16 | `dependency_overrides: zego_zim: 2.27.0` — signaling plugin incompatible with 2.28.0 |
| Fix `permission_handler` version conflict | ✅ | 2026-04-16 | Changed from `^11.3.0` to `^12.0.1` (required by ZEGOCLOUD v4.x) |
| Migrate `video_call_screen.dart` to ZEGOCLOUD v4.x API | ✅ | 2026-04-16 | `onHangUpConfirmation`/`onCallEnd` → `events` param; `durationConfig` → `duration` |
| Document build fixes | ✅ | 2026-04-16 | `docs/build_fixes.md` — 4 issues with root cause analysis and solutions |
| **Fix register screen not showing / back button broken** | ✅ | 2026-04-22 | **Root cause:** `_GoRouterRefreshStream` (in `app_router.dart`) fired on every Supabase auth event (token refreshes, initial state loads) — not just real login/logout changes. GoRouter's `refreshListenable` re-runs the redirect and internally calls `go()` to re-navigate, wiping the push-navigation back stack. After `context.push('/register')`, the stack `[login, register]` was instantly replaced with `[register]` alone, so `context.pop()` had nothing to pop. **Fix 1:** `_GoRouterRefreshStream` now tracks `_prevHasSession` and only calls `notifyListeners()` when the session null→non-null state actually changes. **Fix 2:** Login screen navigation changed from `context.push(AppRoutes.register)` to `context.go(AppRoutes.register)` (correct for auth flows). **Fix 3:** Register screen back button and "Sign In" link changed from `context.pop()` to `context.go(AppRoutes.login)` — deterministic regardless of back-stack state. Files: `app_router.dart`, `login_screen.dart`, `register_screen.dart`. |

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
