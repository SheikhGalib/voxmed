# VoxMed Connect — Progress Tracker

> **Last Updated:** 2026-03-28

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

## Phase 2: Health Passport & Records (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Build `MedicalRecord` model + repository | ⏳ | | |
| Connect Health Passport screen to live data | ⏳ | | |
| Implement Scan Records (camera + upload) | ⏳ | | |
| Deploy `gemini-ocr` Edge Function | ⏳ | | |
| Profile editing (avatar upload) | ⏳ | | |

---

## Phase 3: Find Care & Booking (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Build hospital/doctor models + repositories | ⏳ | | |
| Connect Find Care screen to live data | ⏳ | | |
| Build appointment booking flow | ⏳ | | |
| Doctor schedule availability display | ⏳ | | |
| Reviews system | ⏳ | | |

---

## Phase 4: AI Triage (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Deploy `gemini-triage` Edge Function | ⏳ | | |
| Build AI repository + providers | ⏳ | | |
| Connect AI Assistant to live API | ⏳ | | |

---

## Phase 5: Prescriptions & Adherence (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Prescription models + repository | ⏳ | | |
| Adherence logging system | ⏳ | | |
| Medication reminders (Edge Function cron) | ⏳ | | |
| Renewal request + approval flow | ⏳ | | |

---

## Phase 6: Doctor Dashboard (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Clinical Dashboard with live data | ⏳ | | |
| Schedule management | ⏳ | | |
| Approval Queue | ⏳ | | |
| Emergency Absence + auto-reschedule | ⏳ | | |

---

## Phase 7: Collaborative Care (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Consultation sessions + realtime chat | ⏳ | | |
| Specialist invitation flow | ⏳ | | |
| Shared patient data view | ⏳ | | |

---

## Phase 8: Health Analytics (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Adherence charts + vitals trends | ⏳ | | |
| Compliance score visualization | ⏳ | | |
| Wearable data scaffolding | ⏳ | | |

---

## Phase 9: Polish & Launch (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| E2E testing | ⏳ | | |
| Error handling + loading states | ⏳ | | |
| Performance optimization | ⏳ | | |
| Security audit | ⏳ | | |
| App store prep | ⏳ | | |
