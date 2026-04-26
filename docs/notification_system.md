# Notification System — Architecture & Developer Guide

## Overview

VoxMed patients can schedule medication reminders with exact-time push notifications and alarm-style alerts. This document covers the full stack: database schema, Dart services, UI, Android permissions, and the Doc-Panda AI nudge.

---

## Stack

| Layer | Technology |
|---|---|
| Notifications | `flutter_local_notifications ^18.0.0` |
| Scheduling | `timezone ^0.9.4` |
| Permissions | `permission_handler ^11.3.0` |
| Storage | Supabase `medication_schedules` + `adherence_logs` |
| State | Riverpod `StateNotifierProvider` |

---

## Database Schema

### `medication_schedules`

```sql
id                   uuid PK
patient_id           uuid FK → profiles
prescription_item_id uuid FK → prescription_items (nullable)
medication_name      text
dosage               text
frequency            text DEFAULT 'daily'
times_of_day         text[]   -- e.g. {"08:00","20:00"}
days_of_week         int[]    -- null = every day; 1=Mon…7=Sun
is_active            boolean DEFAULT true
notes                text (nullable)
created_at           timestamptz
updated_at           timestamptz
```

RLS: patients can only read/write their own rows (`auth.uid() = patient_id`).

**Run migration:** `supabase/migrations/009_medication_schedules.sql`

---

## Architecture

```
lib/
  models/
    medication_schedule.dart          ← Domain model + todayDoseTimes()
  repositories/
    notification_service.dart         ← Singleton; schedules/cancels notifications
    medication_schedule_repository.dart ← Supabase CRUD + adherence logging
  providers/
    medication_schedule_provider.dart ← Riverpod providers + StateNotifier
  screens/
    medication_schedule_screen.dart   ← Patient UI to create/edit schedules
```

---

## Notification Flow

```
Patient sets a schedule
  └─ MedicationScheduleNotifier.create()
        ├─ repo.create()  →  Supabase INSERT
        └─ NotificationService.scheduleAllReminders()
              └─ for each time in times_of_day × lookaheadDays (7):
                    plugin.zonedSchedule(stableId, ...)
```

### Notification ID Algorithm

IDs must be deterministic (stable across restarts) and fit in `int32`:

```dart
String key = '${scheduleId}_${dayOffset}_${hour}_$minute';
int hash = 7;
for (int char in key.codeUnits) { hash = 31 * hash + char; }
int notifId = hash.abs() % 2147483647;
```

---

## Android Permissions

| Permission | Purpose |
|---|---|
| `POST_NOTIFICATIONS` | Show notifications (Android 13+) |
| `SCHEDULE_EXACT_ALARM` | Exact-time alarms (Android 12+) |
| `USE_EXACT_ALARM` | Alternative for Android 13+ |
| `RECEIVE_BOOT_COMPLETED` | Restore alarms after reboot |
| `VIBRATE`, `WAKE_LOCK` | Tactile feedback + wake CPU |

Runtime request is handled by `NotificationService.requestPermissions()`, called before the patient first saves a schedule.

---

## Notification Channels

| Channel ID | Name | Importance |
|---|---|---|
| `medication_reminder` | Medication Reminders | High |
| `medication_alarm` | Medication Alarms | Max + full-screen |

The alarm channel uses `fullScreenIntent: true` and `AndroidNotificationCategory.alarm` — this overrides Do Not Disturb on Android when granted by the OS.

---

## Adherence Logging

When a notification is tapped with the "Taken ✓" action, the app should call:

```dart
await repo.logAdherence(
  patientId: uid,
  scheduledTime: originalTime,
  status: 'taken',
  scheduleId: ...,
  medicationName: ...,
);
```

Status values: `taken` | `missed` | `skipped`

---

## Doc-Panda AI Nudge

On `AiAssistantScreen.initState()`, before speaking the default greeting, the app reads `overdueReminderProvider`. If any dose was due in the last 2 hours and not yet logged as taken, the AI greets with:

> "Hi! Did you take your **Metformin** — it was scheduled for 08:00? Let me know and I can help you track it."

This check is silent on error (falls back to default greeting).

---

## UI Entry Points

| Location | Action |
|---|---|
| Dashboard "MONITORING" card | "SCHEDULE YOUR MEDICINE" chip → `/medication-schedule` |
| Dashboard mini-card | "UPCOMING MEDICATION" chip shows next dose name + time |
| Health Insights screen | 30-day Commit Rate + Intake Trend chart + Upcoming Doses |
| AI Assistant | Auto-nudge if overdue dose detected |

---

## Testing

Run: `flutter test test/notification_test.dart`

Covers:
- `MedicationSchedule.fromJson` / `toJson` / `copyWith`
- `todayDoseTimes()` — day-of-week filtering
- `recentlyDueTimes()` — past/future window logic
- Notification ID stability and int32 safety (22 tests)

---

## User Setup Steps

1. **Run migration:** Execute `supabase/migrations/009_medication_schedules.sql` in Supabase SQL Editor.
2. **Build:** `flutter pub get && flutter build apk`
3. **Android 12+:** On first reminder save, the app requests `SCHEDULE_EXACT_ALARM`. If the user denies it, notifications still fire but may be slightly delayed.
4. **Android 13+:** `POST_NOTIFICATIONS` permission dialog appears automatically.
