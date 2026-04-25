# VoxMed — Build Fix Documentation

> **Date:** 2026-04-16  
> **Environment:** Flutter 3.38.9 · Dart 3.10.8 · Gradle 8.13 · AGP 8.11.1 · Kotlin 2.2.20 · Windows 11

This document covers the build failures encountered after integrating the ZEGOCLOUD video calling SDK and how each was resolved.

---

## Issue 1: Java 17 Toolchain Not Found

### Error

```
A problem occurred configuring project ':flutter_callkit_incoming'.
> Failed to calculate the value of task ':flutter_callkit_incoming:compileDebugJavaWithJavac'
  property 'javaCompiler'.
> Cannot find a Java installation on your machine matching:
  {languageVersion=17, vendor=any, implementation=vendor-specific}.
```

### Root Cause

The `flutter_callkit_incoming` plugin (v2.5.8, a transitive dependency of `zego_uikit_prebuilt_call`) declares a **Java 17 toolchain requirement** in its Gradle build. The development machine only had **JDK 21** installed (`C:\Program Files\Java\jdk-21.0.10`) and Android Studio's bundled **JBR 21.0.9**. No JDK 17 was available, and Gradle's default toolchain resolution has no ability to download missing JDKs on its own.

### Fix

Added the **Foojay Toolchain Resolver** plugin to `android/settings.gradle.kts`. This enables Gradle to automatically download the required JDK 17 from the Adoptium (Eclipse Temurin) API at build time.

**File changed:** `android/settings.gradle.kts`

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // ↓ Added to auto-provision JDK 17 for flutter_callkit_incoming
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.9.0"
}
```

### Result

On the next build, Gradle downloaded JDK 17 via the Adoptium API and the toolchain resolution error was eliminated. The downloaded JDK is cached in `~/.gradle/jdks/` for future builds.

---

## Issue 2: `zego_zim` API Incompatibility (Dart Compilation Error)

### Error

```
../../.pub-cache/hosted/pub.dev/zego_uikit_signaling_plugin-2.8.20/lib/src/internal/event_center.dart:53:49:
Error: A value of type 'void Function(ZIM, List<ZIMMessageReaction>)' can't be
assigned to a variable of type 'void Function(ZIM, ZIMMessageReactionsChangedEventResult)?'.
```

### Root Cause

This is a **version incompatibility** in the ZEGOCLOUD package ecosystem:

1. `zego_uikit_prebuilt_call: 4.22.4` depends on `zego_uikit_signaling_plugin: 2.8.20` (the only version available on pub.dev).
2. `zego_uikit_signaling_plugin: 2.8.20` depends on `zego_zim: ^2.21.1+1`.
3. Dart's pub resolver picks the latest matching version: `zego_zim: 2.28.0`.
4. **`zego_zim 2.28.0` introduced a breaking API change:** the `onMessageReactionsChanged` callback parameter was changed from `List<ZIMMessageReaction>` to `ZIMMessageReactionsChangedEventResult`.
5. `zego_uikit_signaling_plugin 2.8.20` still uses the old signature, causing a compile-time type mismatch.

This is an upstream bug — no compatible combination of these packages exists without a manual override.

### Approaches Tried (Failed)

| Approach | Result |
|----------|--------|
| Remove `zego_uikit_signaling_plugin` from direct dependencies | Still resolves as a transitive dependency via `zego_uikit_prebuilt_call` at the same version (2.8.20) |
| Upgrade to `zego_uikit_signaling_plugin: ^2.10.0` | Version does not exist — `2.8.20` is the only release on pub.dev |

### Fix

Added a `dependency_overrides` section to `pubspec.yaml` to pin `zego_zim` to version `2.27.0` (the last version before the breaking callback change):

**File changed:** `pubspec.yaml`

```yaml
dependency_overrides:
  zego_zim: 2.27.0
```

This forces pub to use `zego_zim 2.27.0` regardless of what `zego_uikit_signaling_plugin` requests, keeping the API signatures compatible.

### Result

`flutter pub get` succeeds with a warning: `! zego_zim 2.27.0 (overridden) (2.28.0 available)`. The Dart compilation error is eliminated.

### When to Remove This Override

Monitor [pub.dev/packages/zego_uikit_signaling_plugin](https://pub.dev/packages/zego_uikit_signaling_plugin) for a new release that is compatible with `zego_zim 2.28.0+`. Once an updated signaling plugin is available, the `dependency_overrides` section can be removed and normal version resolution will work.

---

## Issue 3: `permission_handler` Version Conflict

### Error

```
Because zego_uikit_prebuilt_call >=4.0.0 depends on permission_handler ^12.0.1
and voxmed depends on permission_handler ^11.3.0, zego_uikit_prebuilt_call
>=4.0.0 is forbidden.
```

### Root Cause

The initial `pubspec.yaml` specified `permission_handler: ^11.3.0`, but `zego_uikit_prebuilt_call 4.x` requires `permission_handler: ^12.0.1`. These version constraints are mutually exclusive under Dart's pub resolver.

### Fix

Updated the version constraint in `pubspec.yaml`:

```yaml
# Before
permission_handler: ^11.3.0

# After
permission_handler: ^12.0.1
```

---

## Issue 4: ZEGOCLOUD v4.x API Changes in `video_call_screen.dart`

### Error

```
lib/screens/video_call_screen.dart:68:11: Error: No named parameter with the
name 'onHangUpConfirmation'.
lib/screens/video_call_screen.dart:80:11: Error: No named parameter with the
name 'onCallEnd'.
lib/screens/video_call_screen.dart:93:13: Error: No named parameter with the
name 'durationConfig'.
```

### Root Cause

The video call screen was written against the ZEGOCLOUD v3.x API. In v4.x:
- `onHangUpConfirmation` and `onCallEnd` moved from the config cascade into the `events` parameter.
- `durationConfig` was renamed to `duration`.

### Fix

Rewrote the `ZegoUIKitPrebuiltCall` widget construction in `lib/screens/video_call_screen.dart` to use the v4.x API:

```dart
ZegoUIKitPrebuiltCall(
  appID: ZegoConfig.appID,
  appSign: ZegoConfig.appSign,
  userID: userId,
  userName: userName,
  callID: roomId,
  config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
    ..duration.isVisible = true,
  events: ZegoUIKitPrebuiltCallEvents(
    onHangUpConfirmation: (event) async { /* ... */ },
    onCallEnd: (event, defaultAction) async { /* ... */ },
  ),
)
```

---

## Summary of Changed Files

| File | Change |
|------|--------|
| `android/settings.gradle.kts` | Added `foojay-resolver-convention` plugin for JDK 17 auto-download |
| `pubspec.yaml` | Updated `permission_handler` to `^12.0.1`; added `dependency_overrides` for `zego_zim: 2.27.0` |
| `lib/screens/video_call_screen.dart` | Migrated to ZEGOCLOUD v4.x API (`events` parameter, `duration` rename) |
