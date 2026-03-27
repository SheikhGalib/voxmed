# VoxMed Connect — Progress Tracker

> **Last Updated:** 2026-03-28

---

## Legend

- ✅ Done
- 🔄 In Progress
- ⏳ Not Started

---

## Phase 0: Project Setup & Design (Current)

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

## Phase 1: Foundation & Auth (⏳ Not Started)

| Task | Status | Date | Notes |
|------|--------|------|-------|
| Add `supabase_flutter` + `flutter_dotenv` | ⏳ | | |
| Initialize Supabase client in `main.dart` | ⏳ | | |
| Run database migration in Supabase | ⏳ | | Create enums, tables, indexes, RLS, triggers |
| Create data models (`UserProfile`, etc.) | ⏳ | | `lib/models/` |
| Build `AuthRepository` | ⏳ | | signUp, signIn, signOut, getSession |
| Build Login screen | ⏳ | | |
| Build Register screen | ⏳ | | With role selection |
| Add auth guard to router | ⏳ | | Redirect unauthenticated users |
| Add role-based routing | ⏳ | | Patient shell vs Doctor shell |
| Add `flutter_riverpod` | ⏳ | | |
| Create storage buckets | ⏳ | | avatars, reports, prescriptions |

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
