# VoxMed Flutter App — Walkthrough

## What Was Built

A complete Flutter/Android medical healthcare app (**VoxMed**) implemented from 13 Stitch design screens. The app includes patient-facing and clinical/professional screens with full navigation.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            # All color constants
│   │   └── app_theme.dart             # Material 3 theme
│   └── router/
│       └── app_router.dart            # GoRouter with shell route
├── widgets/
│   ├── voxmed_app_bar.dart            # Branded app bar
│   ├── voxmed_bottom_nav.dart         # 4-tab bottom nav
│   ├── voxmed_card.dart               # Reusable card
│   └── ai_fab.dart                    # AI Triage FAB
└── screens/
    ├── dashboard_screen.dart           # Welcome banner, voice tracker, appointments
    ├── health_analytics_screen.dart    # BP trends, medication adherence, vitals
    ├── health_passport_screen.dart     # Upload records, clinical timeline
    ├── find_care_screen.dart           # Search doctors, filter chips, facility
    ├── doctor_booking_detail_screen.dart # Date/time picker, booking confirm
    ├── ai_assistant_screen.dart        # Chat interface with AI triage bot
    ├── scan_records_screen.dart        # Document scanner, OCR, extracted data
    ├── prescription_renewals_screen.dart # Automated renewal hub, medication cards
    ├── live_consultation_screen.dart   # Real-time vitals, AI differentials
    ├── clinical_dashboard_screen.dart  # Dark stats, schedule, compliance
    ├── collaborative_hub_screen.dart   # FHIR file share, treatment thread
    └── approval_queue_screen.dart      # Priority queue, approve/deny actions
```

## Design System

| Token | Value |
|-------|-------|
| Primary | `#1B6D24` (green) |
| Secondary | `#466370` (blue-grey) |
| Tertiary | `#4B6551` (sage green) |
| Headlines | Manrope (extrabold) |
| Body/Labels | Inter (regular/medium) |
| Card Radius | 24px |
| Framework | Material 3 |

## Navigation Architecture

- **Shell Route** (4 tabs with bottom nav): Dashboard → Find Care → Passport → Health
- **Full-screen routes**: AI Assistant, Doctor Booking, Scan Records, Prescription Renewals, Live Consultation, Clinical Dashboard, Collaborative Hub, Approval Queue
- **FAB**: Green gradient button → AI Triage Assistant

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | ✅ 0 issues |
| Debug APK build | ⚠️ Requires `ANDROID_HOME` env variable |

> [!NOTE]
> The APK build requires the Android SDK to be configured. Set the `ANDROID_HOME` environment variable and run `flutter build apk --debug` to compile.

## Design Assets

- Screenshots: `d:\WORK\voxmed\design\screenshots\` (13 files)
- HTML source: `d:\WORK\voxmed\design\html\` (13 files)
