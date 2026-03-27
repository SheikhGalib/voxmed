# VoxMed Connect

> **Your Personal Health Assistant** — An integrated healthcare ecosystem bridging the communication gap between patients and clinicians.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-BaaS-3ECF8E?logo=supabase)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Gemini-AI-4285F4?logo=google)](https://ai.google.dev)

---

## What is VoxMed Connect?

VoxMed Connect is a cross-platform mobile healthcare app built with **Flutter** and powered by **Supabase** (backend) and **Google Gemini** (AI). It serves two user roles:

- **Patients** — Book appointments, manage a digital health passport, get AI-driven symptom triage, track medication adherence, and upload/scan medical reports with OCR.
- **Doctors** — Manage daily schedules, view patient compliance data, approve prescription renewals, collaborate with specialists, and handle emergency absences with auto-rescheduling.

---

## Quick Links to Documentation

| Document | What It Covers |
|----------|----------------|
| 📋 [PRD](docs/PRD.md) | Product requirements, feature specs, personas, technical architecture overview |
| 🗄️ [Database Schema](docs/database_schema.md) | All 19 tables, enums, RLS policies, storage buckets, indexes, triggers, and **step-by-step Supabase setup** |
| 🗺️ [Development Plan](docs/development_plan.md) | 9-phase roadmap, REST API principles, project structure, state management strategy, error handling |
| 📊 [Data Flow Diagrams](docs/dfd.md) | Context diagram, Level-0 DFD, and 7 Level-1 DFDs (Mermaid) |
| 📈 [Progress](docs/progress.md) | What's been done so far and what's next |

---

## Tech Stack

| Layer          | Technology                         | Purpose                                |
|----------------|------------------------------------|----------------------------------------|
| **Frontend**   | Flutter (Dart)                     | Cross-platform mobile app              |
| **Routing**    | GoRouter                          | Declarative navigation, deep linking   |
| **State**      | Riverpod (planned)                | Reactive state management              |
| **Backend**    | Supabase PostgreSQL               | Database, Auth, Storage, Realtime      |
| **Serverless** | Supabase Edge Functions (Deno)    | Secure API calls, business logic       |
| **AI**         | Google Gemini API                 | OCR, triage, SOAP notes               |
| **Design**     | Material 3, Manrope + Inter fonts | Modern, green-themed healthcare UI     |

---

## Project Structure

```
voxmed/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── config/                  # Supabase client config
│   │   ├── constants/               # App-wide constants, enums
│   │   ├── router/
│   │   │   └── app_router.dart      # GoRouter with role-based shells
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # Material 3 color scheme
│   │   │   └── app_theme.dart       # Full ThemeData config
│   │   └── utils/                   # Extensions, validators, error handler
│   ├── models/                      # Data models (fromJson/toJson)
│   ├── repositories/                # Supabase data access layer
│   ├── providers/                   # Riverpod state providers
│   ├── screens/
│   │   ├── auth/                    # Login, Register, Role Selection
│   │   ├── patient/                 # 8 patient-facing screens
│   │   └── doctor/                  # 4 doctor-facing screens
│   └── widgets/                     # Shared UI components
├── design/
│   ├── screenshots/                 # 13 UI design mockups (PNG)
│   └── html/                        # 13 HTML prototype screens
├── docs/                            # All project documentation
├── .env                             # Supabase keys (gitignored)
└── pubspec.yaml                     # Flutter dependencies
```

---

## Database Schema (Summary)

19 PostgreSQL tables organized by domain:

| Domain              | Tables                                                           |
|---------------------|------------------------------------------------------------------|
| **Users**           | `profiles`                                                       |
| **Healthcare**      | `hospitals`, `doctors`, `doctor_schedules`, `doctor_absences`    |
| **Appointments**    | `appointments`                                                   |
| **Medical Records** | `medical_records`                                                |
| **Prescriptions**   | `prescriptions`, `prescription_items`, `prescription_renewals`   |
| **Adherence**       | `adherence_logs`                                                 |
| **AI**              | `ai_conversations`, `ai_messages`                                |
| **Collaboration**   | `consultation_sessions`, `consultation_members`, `consultation_messages` |
| **System**          | `notifications`, `reviews`, `wearable_data`                      |

> **Full schema with SQL →** [docs/database_schema.md](docs/database_schema.md)

---

## API Architecture

VoxMed uses **Supabase PostgREST** (auto-generated REST API from PostgreSQL) with **Row Level Security** for data protection:

```
Flutter App  →  Supabase Auth (JWT)  →  PostgREST API  →  PostgreSQL (RLS)
                                     →  Edge Functions  →  Gemini API
                                     →  Realtime        →  WebSocket subscriptions
                                     →  Storage         →  File uploads
```

Key API domains: Auth, Hospitals, Doctors, Appointments, Records, Prescriptions, Adherence, AI Triage, Consultations, Notifications.

> **Full API routing →** [docs/development_plan.md](docs/development_plan.md)

---

## Screens

### Patient Screens (8)
| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/` | Welcome, adherence tracker, appointments, health pulse |
| Find Care | `/find-care` | Search hospitals/doctors by specialty, ratings |
| Doctor Booking | `/doctor-booking` | Doctor profile, schedule picker, booking |
| Health Passport | `/passport` | Medical records, prescriptions, clinical history |
| Health Analytics | `/health` | Adherence charts, vitals trends, compliance score |
| Scan Records | `/scan-records` | Camera capture, OCR extraction, data review |
| Prescription Renewals | `/prescription-renewals` | Current meds, renewal requests |
| AI Assistant | `/ai-assistant` | Symptom triage chat, doctor suggestions |

### Doctor Screens (4)
| Screen | Route | Description |
|--------|-------|-------------|
| Clinical Dashboard | `/clinical-dashboard` | Today's patients, compliance trends, schedule |
| Approval Queue | `/approval-queue` | Pending prescription renewal requests |
| Collaborative Hub | `/collaborative-hub` | Multi-doctor patient sessions, shared records |
| Live Consultation | `/live-consultation` | Video call + ambient SOAP notes (Phase 2+) |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- A Supabase project ([setup guide](docs/database_schema.md#8-supabase-setup-instructions))

### Run Locally
```bash
# Clone and install
git clone <repo-url>
cd voxmed
flutter pub get

# Set up environment
cp .env.example .env
# Edit .env with your Supabase URL, anon key, and Gemini API key

# Run the database migration in Supabase SQL Editor
# (See docs/database_schema.md → Section 8)

# Launch
flutter run
```

---

## Development Roadmap

| Phase | Focus | Duration |
|-------|-------|----------|
| 1 | Foundation & Auth | Week 1-2 |
| 2 | Health Passport & Records | Week 3-4 |
| 3 | Find Care & Booking | Week 5-6 |
| 4 | AI Triage Assistant | Week 7-8 |
| 5 | Prescriptions & Adherence | Week 9-10 |
| 6 | Doctor Dashboard & Clinical Tools | Week 11-13 |
| 7 | Collaborative Care & Realtime | Week 14-15 |
| 8 | Health Analytics & Wearables | Week 16-17 |
| 9 | Polish, Testing & Launch | Week 18-20 |

> **Full plan →** [docs/development_plan.md](docs/development_plan.md)

---

## For AI Assistants (Context Guide)

If you're an AI working on this codebase, here's the recommended reading order:

1. **Start here:** This README for project overview
2. **Feature requirements:** [docs/PRD.md](docs/PRD.md)
3. **Database first:** [docs/database_schema.md](docs/database_schema.md) — all 19 tables, enums, RLS
4. **Architecture & plan:** [docs/development_plan.md](docs/development_plan.md) — project structure, API routing, phases
5. **Data flows:** [docs/dfd.md](docs/dfd.md) — how data moves through the system
6. **Current status:** [docs/progress.md](docs/progress.md) — what's done and what's next
7. **Design reference:** `design/screenshots/` — 13 PNG mockups of all screens
8. **Existing code:** `lib/` — current theme, router, and screen stubs

---

## License

Private — All rights reserved.