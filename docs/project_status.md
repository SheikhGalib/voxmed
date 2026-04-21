# VoxMed Connect — Full Project Status Report

> **Generated:** 2026-04-20  
> **Stack:** Flutter · Supabase · Gemini API · ZEGOCLOUD  
> **Current Version:** 0.1.0

---

## 1. Project Overview

**VoxMed Connect** is a cross-platform healthcare mobile application (Flutter/Android+iOS) built on Supabase as a backend. It serves two roles — **Patients** and **Doctors** — with dedicated shells and feature sets for each. The platform integrates AI triage (Gemini), voice interaction (speech-to-text + TTS), video consultations (ZEGOCLOUD), medical record OCR, prescription management, collaborative care, and health analytics — all backed by Supabase PostgreSQL, Auth, Storage, Realtime, and Edge Functions.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter 3.x (Dart) |
| State Management | Riverpod 2.6 |
| Routing | GoRouter 17 |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime + Edge Functions) |
| AI | Google Gemini API (via Supabase Edge Functions) |
| Video Calling | ZEGOCLOUD UIKit Prebuilt Call |
| Voice | `speech_to_text` + `flutter_tts` |
| Fonts | Manrope + Inter (Google Fonts) |
| Env Config | `flutter_dotenv` (.env file) |

---

## 3. Architecture

```
Flutter App
├── screens/          ← Pure UI, no business logic
├── providers/        ← Riverpod state (AsyncNotifier / FutureProvider)
├── repositories/     ← All Supabase calls (thin data layer)
├── models/           ← fromJson / toJson data classes
├── core/
│   ├── config/       ← Supabase + ZEGO singletons
│   ├── constants/    ← Route names, table names, enums
│   ├── router/       ← GoRouter with auth guard + role shells
│   ├── theme/        ← Colors, typography (Material 3)
│   └── utils/        ← Validators, extensions, error handler
└── widgets/          ← Shared UI components

Supabase
├── PostgreSQL (22 tables, RLS, 8 enums)
├── Auth (JWT, role in metadata)
├── Storage (avatars/, reports/, prescriptions/)
├── Edge Functions (gemini-triage ✅ deployed)
└── Realtime (appointments, chat, notifications)
```

---

## 4. Database — 22 Tables

| # | Table | Purpose |
|---|---|---|
| 1 | `profiles` | User identity (patient / doctor), extends `auth.users` |
| 2 | `hospitals` | Hospital directory |
| 3 | `doctors` | Doctor profiles, linked to hospitals + profiles |
| 4 | `doctor_schedules` | Weekly availability slots |
| 5 | `appointments` | Bookings (in-person + video), status lifecycle |
| 6 | `medical_records` | Uploaded/scanned health records |
| 7 | `prescriptions` | Issued prescriptions |
| 8 | `prescription_items` | Line items per prescription |
| 9 | `prescription_renewals` | Patient renewal requests + doctor approval |
| 10 | `medications` | Medication master list |
| 11 | `adherence_logs` | Voice-tracked medication compliance events |
| 12 | `ai_conversations` | AI chat session headers |
| 13 | `ai_messages` | AI chat messages (user + assistant) |
| 14 | `notifications` | Push/in-app notification records |
| 15 | `reviews` | Patient reviews of doctors |
| 16 | `consultation_sessions` | Multi-doctor collaborative sessions |
| 17 | `consultation_members` | Doctor invites per session |
| 18 | `consultation_messages` | Realtime chat within a session |
| 19 | `wearable_data` | Biometric data from smartwatch sync |
| 20 | `video_calls` | Video call room records (ZEGOCLOUD) |
| 21 | `call_transcripts` | ASR transcription segments |
| 22 | `emergency_call_requests` | Emergency call queue (early responder) |

---

## 5. Screens Implemented

### Patient Shell (4 tabs)
| Screen | File | Status |
|---|---|---|
| Dashboard | `dashboard_screen.dart` | ✅ Live data |
| Find Care | `find_care_screen.dart` | ✅ Live search (hospital + doctor) |
| Health Passport | `health_passport_screen.dart` | ✅ Live records + prescriptions |
| AI Assistant | `ai_assistant_screen.dart` | ✅ Chat + voice + session mgmt |

### Patient Extra Screens
| Screen | File | Status |
|---|---|---|
| Doctor Booking Detail | `doctor_booking_detail_screen.dart` | ✅ Full booking flow + video toggle |
| Scan Records | `scan_records_screen.dart` | ✅ Camera/gallery → Supabase Storage |
| Health Analytics | `health_analytics_screen.dart` | ✅ Adherence charts + vitals |
| Prescription Renewals | `prescription_renewals_screen.dart` | ✅ Request + status tracking |
| Profile | `profile_screen.dart` | ✅ View (edit/avatar upload pending) |
| Video Call | `video_call_screen.dart` | ✅ ZEGOCLOUD wrapper + hang-up |

### Doctor Shell (3 tabs)
| Screen | File | Status |
|---|---|---|
| Clinical Dashboard | `clinical_dashboard_screen.dart` | ✅ Today's appointments + compliance |
| Approval Queue | `approval_queue_screen.dart` | ✅ Approve/deny renewals |
| Collaborative Hub | `collaborative_hub_screen.dart` | ✅ Live session + chat |

### Auth Screens
| Screen | File | Status |
|---|---|---|
| Login | `auth/login_screen.dart` | ✅ Email/password + validation |
| Register | `auth/register_screen.dart` | ✅ Role toggle (Patient/Doctor) |

---

## 6. Repositories & Providers

| Repository | Provider | Status |
|---|---|---|
| `AuthRepository` | `auth_provider.dart` | ✅ |
| `ProfileRepository` | *(in auth provider)* | ✅ |
| `HospitalRepository` | `hospital_provider.dart` | ✅ |
| `DoctorRepository` | `doctor_provider.dart` | ✅ |
| `AppointmentRepository` | `appointment_provider.dart` | ✅ |
| `MedicalRecordRepository` | `medical_record_provider.dart` | ✅ |
| `PrescriptionRepository` | `prescription_provider.dart` | ✅ |
| `AiRepository` | *(in ai_provider)* | ✅ |
| `VideoCallRepository` | `video_call_provider.dart` | ✅ (model file tracked as added) |
| `AdherenceRepository` | — | ⚠️ File not yet present in `/repositories` |
| `ConsultationRepository` | — | ⚠️ File not yet present in `/repositories` |
| `NotificationRepository` | — | ⚠️ File not yet present in `/repositories` |
| `ReviewRepository` | — | ⚠️ File not yet present in `/repositories` |
| `StorageRepository` | — | ⚠️ File not yet present in `/repositories` |
| `WearableRepository` | — | ⚠️ File not yet present in `/repositories` |

---

## 7. Edge Functions

| Function | Status | Purpose |
|---|---|---|
| `gemini-triage` | ✅ Deployed (Supabase) | AI symptom triage + structured triage JSON |
| `gemini-ocr` | ⏳ Not deployed | OCR extraction from medical images |
| `auto-reschedule` | ⏳ Not built | Emergency absence → rebook + notify |
| `soap-notes` | ⏳ Not built | Gemini SOAP note from call transcription |
| `medication-reminder` | ⏳ Not built | Cron job for adherence push reminders |

---

## 8. What Has Been Done ✅

### Infrastructure & Setup
- [x] Flutter project scaffolded with Material 3, Manrope/Inter fonts
- [x] Supabase client initialized with `flutter_dotenv` env loading
- [x] GoRouter with ShellRoute for patient (4 tabs) and doctor (3 tabs) shells
- [x] Auth guard — unauthenticated users redirected to `/login`
- [x] Role-based routing (patient vs doctor shells)
- [x] Riverpod `ProviderScope` wrapping the entire app
- [x] Design system: `app_colors.dart`, `app_theme.dart` (green primary)
- [x] 13 HTML UI prototypes + screenshots in `design/`

### Core Utilities
- [x] `supabase_config.dart` — Singleton client accessor
- [x] `app_constants.dart` — Routes, table names, storage buckets, 8 enums
- [x] `extensions.dart` — DateTime + String helpers
- [x] `validators.dart` — Email, password, name, phone
- [x] `error_handler.dart` — `AppException`, error/success SnackBars

### Models (9 built)
UserProfile, Hospital, Doctor, DoctorSchedule, Appointment, MedicalRecord, Prescription, Review, NotificationModel

### Auth & Profile
- [x] Login screen with email/password validation and role-based redirect
- [x] Register screen with role toggle (Patient/Doctor) + Supabase metadata
- [x] `AuthRepository` — signUp, signIn, signOut, getSession
- [x] `ProfileRepository` — getProfile, updateProfile, getCurrentUserProfile

### Find Care (Phase 3)
- [x] Hospital + doctor search live from Supabase
- [x] Filter by specialty, rating, availability
- [x] Doctor booking detail with schedule/availability display
- [x] Full appointment booking flow (in-person + video type toggle)
- [x] Reviews seeded and surfaced

### Health Passport & Records (Phase 2)
- [x] Health Passport screen renders live records + prescriptions
- [x] Scan Records: camera/gallery pick → Supabase Storage → DB record
- [x] Dashboard passport card navigates to Health Passport panel
- [x] Dashboard recent reports auto-fetch via `recentMedicalRecordsProvider`

### AI Assistant (Phase 4 — partial)
- [x] `gemini-triage` Edge Function deployed with multi-key fallback (`GEMINI_API_KEY_1..N`)
- [x] `AiRepository.sendMessage()` invokes Edge Function + refreshes providers
- [x] Conversation + message persistence (create, read, delete sessions)
- [x] Chat session controls: new, resume, delete
- [x] Editable system prompts for patient/doctor roles (`system_prompts.json`)
- [x] Foreground voice: speech-to-text input + TTS responses
- [x] Edge Function returns structured triage JSON (specialty + confidence)

### Prescriptions & Adherence (Phase 5)
- [x] Prescription + PrescriptionItem models + repository
- [x] Adherence logging and analytics data connected
- [x] Patient renewal request flow
- [x] Doctor Approval Queue (approve/deny)

### Doctor Dashboard (Phase 6)
- [x] Clinical Dashboard with live data (today's appointments, compliance)
- [x] Approval Queue with approve/deny actions
- [x] Doctor identity rows auto-heal on login/sign-up

### Collaborative Care (Phase 7)
- [x] Consultation session + message data connected to Collaborative Hub UI
- [x] Shared patient data view in hub

### Health Analytics (Phase 8)
- [x] Adherence charts + vitals trends bound to real data
- [x] Compliance score visualization on dashboard
- [x] Wearable data path active via Supabase

### Video Calling — ZEGOCLOUD (Phase 10, Phase 1 partial)
- [x] Dependencies added: `zego_uikit_prebuilt_call`, `zego_uikit_signaling_plugin`, `permission_handler`
- [x] `zego_config.dart` reads ZEGO_APP_ID/ZEGO_APP_SIGN from `.env`
- [x] `VideoCall` model with `VideoCallStatus` enum
- [x] `VideoCallRepository` (Supabase CRUD: create, getByAppointment, updateStatus, completeCall)
- [x] `VideoCallProvider` (Riverpod)
- [x] `VideoCallScreen` with ZEGOCLOUD PrebuiltCall, hang-up confirmation, duration display
- [x] `/video-call` route in GoRouter
- [x] Auto-create video call room on booking confirmation
- [x] Appointment type toggle (In-Person / Video) in booking screen
- [x] Android camera/mic/network permissions in `AndroidManifest.xml`
- [x] Patient dashboard "Join Call" button for video appointments
- [x] Doctor daily schedule shows video call indicator

### Testing & Quality
- [x] 36 unit tests — models, validators, enums (all passing)
- [x] `flutter analyze` — 0 issues (as of Phase 1)

---

## 9. What Is Left ⏳

### High Priority

| Item | Phase | Notes |
|---|---|---|
| **Create Supabase `video_calls` table** | 10 | SQL in `video_calling_implementation.md` §6.1 |
| **Create `call_transcripts` table** | 10 | SQL in §6.2 |
| **Create `emergency_call_requests` table** | 10 | SQL in §6.3 |
| **Add new `notification_type` enum values** | 10 | `video_call_scheduled`, `video_call_starting`, etc. |
| **End-to-end video call test** | 10 | Requires ZEGOCLOUD credentials in `.env` |
| **Deploy `gemini-ocr` Edge Function** | 2 | OCR from medical image uploads |
| **Profile avatar upload** | 2 | Edit profile + upload to `avatars/` bucket |
| **Triage → Find Care deep-link UI** | 4 | Edge function returns specialty; UI to deep-link to filtered Find Care |

### Medium Priority

| Item | Phase | Notes |
|---|---|---|
| **Doctor schedule editing** | 6 | Richer weekly schedule management UI |
| **Specialist invitation flow** | 7 | Invite external doctor into collaborative session |
| **Medication reminder cron** | 5 | Supabase Edge Function on a schedule |
| **Emergency Absence + auto-reschedule** | 6 | Doctor triggers absence → slots auto-rebooked |
| **Missing repositories** | — | `AdherenceRepository`, `ConsultationRepository`, `NotificationRepository`, `ReviewRepository`, `StorageRepository` |
| **ZEGOCLOUD Phase 2** | 10 | Scheduled meeting notifications (Supabase Realtime call invitations) |
| **ZEGOCLOUD Phase 3** | 10 | Emergency calling (early responder queue) |

### Low Priority / Future

| Item | Phase | Notes |
|---|---|---|
| **ZEGOCLOUD Phase 4** | 10 | Real-time ASR transcription via Deepgram |
| **ZEGOCLOUD Phase 5** | 10 | SOAP notes generation (Gemini + `soap-notes` Edge Function) |
| **Wearable sync** | 8 | Actual device SDK integration (currently seeded data) |
| **Ambient SOAP note generation** | PRD | Live consultation audio → auto SOAP |
| **`auto-reschedule` Edge Function** | Dev Plan | Complex rescheduling logic |
| **E2E testing** | 9 | Full integration test suite |
| **Error handling & loading states** | 9 | Consistent UX across all screens |
| **Performance optimization** | 9 | Widget rebuilds, image caching, lazy loading |
| **Security audit** | 9 | OWASP review, RLS policy audit |
| **App Store preparation** | 9 | Icons, splash, store listings |
| **Doctor Web Dashboard** | PRD | Flutter Web or React portal |
| **iOS support & testing** | — | Currently Android-only build |

---

## 10. Known Issues / Gaps

| Issue | Impact | Status |
|---|---|---|
| `zego_uikit_prebuilt_call` & `permission_handler` listed in progress notes but **not yet in `pubspec.yaml`** | Video call screen will fail to compile | ⚠️ Needs `pubspec.yaml` update |
| Several repositories in `development_plan.md` not yet created (adherence, consultation, notification, review, storage, wearable) | Some screens may use inline Supabase calls instead of proper repository layer | ⚠️ Architecture debt |
| `gemini-ocr` Edge Function not deployed | Scan Records stores the file but does not extract structured data | ⚠️ Partial feature |
| Supabase `video_calls` / `call_transcripts` / `emergency_call_requests` tables not yet created in DB | Video call repository calls will fail at runtime | 🔴 Blocker for video calling |
| Medication reminders are notification records only — no cron yet | Reminders don't fire automatically | ⚠️ Partial feature |

---

## 11. Progress Summary

| Phase | Name | Status | % |
|---|---|---|---|
| 0 | Setup & Design | ✅ Complete | 100% |
| 1 | Foundation & Auth | ✅ Complete | 100% |
| 2 | Health Passport & Records | 🔄 In Progress | ~75% |
| 3 | Find Care & Booking | ✅ Complete | 100% |
| 4 | AI Assistant | 🔄 In Progress | ~80% |
| 5 | Prescriptions & Adherence | ✅ Complete* | ~90% |
| 6 | Doctor Dashboard | 🔄 In Progress | ~85% |
| 7 | Collaborative Care | ✅ Complete* | ~85% |
| 8 | Health Analytics | ✅ Complete* | ~90% |
| 9 | Polish & Launch | ⏳ Not Started | 0% |
| 10 | Video Calling (ZEGOCLOUD) | 🔄 In Progress | ~40% |

> \* "Complete" means live data connected; some sub-features (cron, invites, wearable SDK) are stubs.

**Overall Estimated Completion: ~75%**
