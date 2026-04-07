# VoxMed Connect — Progress Tracker

> **Last Updated:** 2026-04-08

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

## Phase 2: Health Passport & Records (✅ Completed)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Build `MedicalRecord` model + repository | ✅ | 2026-04-07 | Repository/provider wired to Supabase records |
| Connect Health Passport screen to live data | ✅ | 2026-04-07 | Passport now renders recent records and prescriptions |
| Implement Scan Records (camera + upload) | ⏳ | | UI remains pending |
| Deploy `gemini-ocr` Edge Function | ⏳ | | Pending backend function deployment |
| Profile editing (avatar upload) | ⏳ | | Pending |

---

## Phase 3: Find Care & Booking (🔄 In Progress)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Build hospital/doctor models + repositories | ✅ | 2026-03-28 | Hospital and doctor data layer completed |
| Connect Find Care screen to live data | ✅ | 2026-04-08 | Hospital search and doctor listing are live; search now covers doctors too |
| Build appointment booking flow | ✅ | 2026-04-07 | Doctor detail and booking flow connected |
| Doctor schedule availability display | ✅ | 2026-04-07 | Schedules load from repository/providers |
| Reviews system | ✅ | 2026-04-07 | Review data seeded and surfaced in booking context |

---

## Phase 4: AI Triage (🔄 In Progress)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Deploy `gemini-triage` Edge Function | ⏳ | | Backend deployment still pending |
| Build AI repository + providers | ✅ | 2026-04-07 | Conversation/message providers added |
| Connect AI Assistant to live API | ✅ | 2026-04-07 | AI Assistant screen now reads/writes Supabase conversations/messages |

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
