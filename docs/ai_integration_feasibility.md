# VoxMed — AI Integration Feasibility & Research Notes

This document summarizes feasibility, platform constraints, and required permissions for the requested AI features:

- Proactive medication reminders (including “talking notifications” / voice reminders)
- “Aggressive” assistant behavior / escalation patterns
- Blocking or limiting entertainment apps if meds aren’t taken
- Camera-only pill verification (no gallery upload)

It also captures relevant official documentation and example open-source projects for further study.

> Important: This is a technical feasibility/policy risk summary, not legal advice. Before shipping anything that affects device behavior (notifications, accessibility, app restrictions), review current Google Play policies, Apple App Store rules, and local healthcare privacy regulations.

---

## Current state in this repo

Implemented already:

- Cute AI mascot FAB entrypoint with wave animation and “Hi” bubble shown on the first home-tab view.
  - Implemented in `lib/widgets/ai_fab.dart`
  - Wired into both patient and doctor shells in `lib/core/router/app_router.dart`
- Foreground (in-app) voice scaffolding on the AI assistant screen:
  - Uses `speech_to_text` + `flutter_tts`
  - Implemented in `lib/screens/ai_assistant_screen.dart`
- Android mic permission added:
  - `android.permission.RECORD_AUDIO` in `android/app/src/main/AndroidManifest.xml`
- Dependencies added in `pubspec.yaml`:
  - `speech_to_text: ^7.3.0`
  - `flutter_tts: ^4.2.5`

---

## 1) Proactive medication reminders (notifications)

### What is feasible (good reliability)

**Cross-platform reminders via notifications are feasible**:

- Use a local notification plugin to schedule notifications at medication times.
- Sync schedules from Supabase → cache locally → schedule notifications on-device.
- When schedule changes, cancel/reschedule upcoming reminders.

Recommended approach:

- One notification plugin only (don’t mix two different local notification engines).
- Keep reminders “notification-first”; if the user taps, deep-link into a “Take dose now” screen.

### Key Android constraints

- Android 13+ requires requesting the runtime permission `POST_NOTIFICATIONS` before posting most notifications.
  - Official doc: https://developer.android.com/guide/topics/ui/notifiers/notification-permission
- Scheduled notifications can be impacted by OEM battery optimizations; device-specific behavior is a known real-world problem.
  - Reference: https://dontkillmyapp.com/

### Key iOS constraints

- iOS allows scheduled local notifications through `UNUserNotificationCenter`, but the system owns delivery.
- You cannot run arbitrary code at exact times in the background “just to talk”; use notifications to get user attention.

---

## 2) “Talking notifications” / proactive voice reminders

### What users want

At medication time:

- The phone shows a notification
- AND the assistant speaks out loud (TTS) even if the app is closed

### Feasibility summary

**Not reliably feasible on iOS or Android as a general background behavior**.

- “Speaking” implies active audio output from your process.
- Mobile OSes limit background execution and background audio for privacy/battery.

### What is feasible instead (recommended)

Tiered options that stay within platform expectations:

1) **Notification with sound**
   - Use a notification channel with an audible sound (Android) / notification sound (iOS).
   - This is the closest “talking-like” experience while remaining OS-managed.

2) **Open-app voice**
   - When the user taps the reminder and the app is foregrounded, speak the message via `flutter_tts`.

3) **Foreground service (Android only, with strong UX constraints)**
   - You can keep a foreground service running (persistent notification visible) and speak using TTS.
   - This is intrusive and high-risk for store review if used aggressively.
   - Foreground services must be user-noticeable and show a persistent notification.

### Full-screen/urgent interruptions are restricted

- Full-screen intents have stricter rules on newer Android versions.
  - AOSP doc (Android 14+ behavior): https://source.android.com/docs/core/permissions/fsi-limits
- Google Play policy also restricts `USE_FULL_SCREEN_INTENT` usage and requires user consent when not auto-granted.
  - Policy page includes “Full-Screen Intent Permission”: https://support.google.com/googleplay/android-developer/answer/9888170

---

## 3) “Aggressive assistant” behavior (escalation)

### Feasible patterns (policy-friendly)

A safe escalation ladder that remains user-controlled:

- **Level 0 (default):** gentle reminders, easy snooze, clear controls
- **Level 1:** persistent reminders (still dismissible)
- **Level 2:** optional caregiver/family notification (user opt-in), or “notify doctor” workflow
- **Level 3:** optional phone call/SMS via user action (avoid automatic/hidden behavior)

Principles:

- Always allow the user to mute, change schedule, and opt out.
- Provide a “why am I seeing this” explanation.
- Avoid harassment patterns (rapid repeating alerts, blocking UI, preventing dismiss).

### Things to avoid

- Anything that prevents normal device use without explicit consent.
- Anything that manipulates users into granting sensitive permissions (Google Play policy explicitly warns against manipulation).
  - Policy: “Restricted Permissions” section: https://support.google.com/googleplay/android-developer/answer/9888170

---

## 4) Blocking / limiting entertainment apps if meds aren’t taken

### High-level feasibility

**On typical consumer devices (BYOD), this is generally not feasible in a compliant way.**

- iOS: third-party apps cannot block other apps.
- Android: consumer apps cannot reliably block other apps without privileged device management, accessibility-based workarounds, or VPN-style filtering.

### What Android CAN do (in specific deployments)

#### A) Fully managed “dedicated devices” / enterprise control

If the device is company-owned and fully managed, Android Enterprise APIs allow kiosk-like control:

- Dedicated devices overview: https://developer.android.com/work/dpc/dedicated-devices
- Lock task mode (kiosk allowlisting): https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode
- Building a DPC (Device Policy Controller): https://developer.android.com/work/dpc/build-dpc

This approach is only realistic if the clinic/organization manages devices (not typical patient BYOD).

#### B) Accessibility-service-based “blocker” apps (high policy risk)

Many “focus / blocker” apps use Accessibility Service to detect and interrupt certain apps.

However, Google Play policy places strict limits on Accessibility API usage:

- Accessibility API **cannot** be used to:
  - Change user settings without permission
  - Work around built-in security/privacy controls
  - Use UI in a deceptive way
- It is also not designed for apps that “autonomously initiate, plan, and execute actions or decisions”.

Policy reference (Accessibility API section): https://support.google.com/googleplay/android-developer/answer/9888170

Practical takeaway:

- A medication app that tries to block entertainment apps via Accessibility is likely to trigger review/policy issues and user trust concerns.

#### C) Usage access (UsageStatsManager)

Usage access can provide app usage statistics (after the user grants special access), but **does not provide a clean, supported “block other apps” capability**.

UsageStatsManager API reference is a starting point for understanding what’s available, but enforcement isn’t.

### Recommended alternative designs

If the goal is adherence improvement:

- Make the “dose confirmation” flow fast and rewarding.
- Provide optional accountability features:
  - share adherence streak with caregiver (opt-in)
  - “missed dose” alerts to doctor/caregiver (opt-in)
- Provide user guidance to enable OS focus modes, but don’t try to enforce device-wide blocks.

### Example open-source projects (for study only)

These are NOT endorsements and should not be copied blindly (policy/security concerns), but they show common technical approaches:

- Medication reminders (Flutter):
  - https://github.com/iamnijat/healsense
  - https://github.com/OssHeikal/MedAlert
  - https://github.com/marcuswkl/gdscsu-medimate-solution-challenge-2022
  - https://github.com/MoazSalem/pills-reminder-flutter
- “Block shorts / focus apps” using accessibility/VPN approaches:
  - https://github.com/sushant-XD/ShortsBlocker
  - https://github.com/Shanners45/FocusLock
  - https://github.com/jose-antony-02/FocusGuard

---

## 5) Camera-only pill verification (no gallery upload)

### What is feasible

**Camera-only capture flow is feasible**:

- Use the camera (not the gallery) as the only input method.
- Do not request broad gallery/media permissions.
- Store the captured image in app-private storage and upload to backend for verification.

This meets the requirement “no gallery upload” from the app UX perspective.

### What is NOT fully enforceable

Even if you require “camera-only” inside the app:

- A user could take a photo of a photo (spoofing).
- A user could use another phone/camera.

So this feature provides friction and evidence, but it is not a guaranteed truth mechanism.

### Recommended verification hardening (optional)

- Require a short **video** clip instead of a photo.
- Add “challenge” prompts (“show the pill, then rotate it”, “show today’s date on screen”) — still spoofable but raises effort.
- Record capture time, device info, and basic liveness checks.

### Permissions

- Android: `android.permission.CAMERA` (only if you use camera plugin that requires it)
- iOS: `NSCameraUsageDescription`

If you record video/audio:

- Android: `android.permission.RECORD_AUDIO`
- iOS: `NSMicrophoneUsageDescription`

---

## Permissions checklist (by feature)

### Voice (speech-to-text)

- Android:
  - `android.permission.RECORD_AUDIO`
  - (Potentially) `android.permission.INTERNET` (already present) depending on recognition engine
- iOS:
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`

### TTS (text-to-speech)

- Generally no explicit runtime permission, but behavior varies by device/vendor.

### Notifications

- Android 13+:
  - `android.permission.POST_NOTIFICATIONS` (runtime)
  - Consider policy implications and request in context
  - Official: https://developer.android.com/guide/topics/ui/notifiers/notification-permission
- Android exact timing (if required):
  - `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` (policy-restricted; Play review)
  - Policy reference: https://support.google.com/googleplay/android-developer/answer/9888170
- Android full-screen interruptions (if ever considered):
  - `USE_FULL_SCREEN_INTENT` (restricted on Android 14+; often needs user consent)
  - AOSP limits: https://source.android.com/docs/core/permissions/fsi-limits
  - Play policy: https://support.google.com/googleplay/android-developer/answer/9888170

### App “blocking” / enforcement attempts

- Usage access:
  - `android.permission.PACKAGE_USAGE_STATS` (special app access; user must grant)
- Accessibility service:
  - `android.permission.BIND_ACCESSIBILITY_SERVICE` (declared on the service)
  - High policy and trust risk; see Play policy constraints

### Camera-only verification

- Android: `android.permission.CAMERA`
- iOS: `NSCameraUsageDescription`

---

## Implementation recommendations (practical plan)

### MVP (recommended)

- Notifications: implement scheduled reminders + deep-link into “take dose” flow.
- Voice: keep TTS/STT inside the assistant screen only (foreground).
- Verification: implement camera-only capture screen; don’t offer gallery.

### Advanced (high-risk / requires careful review)

- Any attempt to talk from background or block other apps.
- Any accessibility-service approach.
- Any full-screen intent approach.

---

## Package/tooling references

Flutter packages (starting points):

- `speech_to_text`: https://pub.dev/packages/speech_to_text
- `flutter_tts`: https://pub.dev/packages/flutter_tts
- Notifications:
  - `flutter_local_notifications`: https://pub.dev/packages/flutter_local_notifications
  - `awesome_notifications`: https://pub.dev/packages/awesome_notifications
- Background scheduling:
  - `workmanager`: https://pub.dev/packages/workmanager

Notification permission docs:

- Android notification runtime permission: https://developer.android.com/guide/topics/ui/notifiers/notification-permission

Background reliability reality check:

- OEM background killing overview: https://dontkillmyapp.com/

Google Play policy (restricted permissions + Accessibility API limits):

- https://support.google.com/googleplay/android-developer/answer/9888170

Android 14 full-screen intent limits (AOSP docs):

- https://source.android.com/docs/core/permissions/fsi-limits

Android Enterprise (only for managed devices / kiosk scenarios):

- Dedicated devices overview: https://developer.android.com/work/dpc/dedicated-devices
- Lock task mode: https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode
- Build a DPC: https://developer.android.com/work/dpc/build-dpc

---

## Suggested search terms (Google/GitHub/YouTube)

Medication reminders:

- “flutter medication reminder local notifications timezone”
- “flutter_local_notifications zonedSchedule medication reminder”

Voice assistant in Flutter:

- “speech_to_text flutter_tts conversation UI”

Background scheduling pitfalls:

- “Android exact alarm permission USE_EXACT_ALARM SCHEDULE_EXACT_ALARM”
- “dontkillmyapp Xiaomi notifications”

App blocking / focus apps (research only):

- “Android AccessibilityService block apps policy”
- “Android lock task mode kiosk allowlist”
- “Android Enterprise dedicated devices DPC lock task mode”
