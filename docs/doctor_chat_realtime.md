# VoxMed — Doctor-to-Doctor Chat: Realtime Architecture & Fix Log

> **Date:** 2026-04-25  
> **Scope:** `DoctorChatScreen`, `CollaborationRepository`, `consultation_sessions/members/messages` tables

---

## 1. Is it True Realtime? Yes.

The chat uses **Supabase Realtime** via the Flutter SDK's `.stream()` API. This is a genuine WebSocket-based push channel — no polling.

### How it works end-to-end

```
Doctor A (Flutter)                 Supabase (PostgreSQL + Realtime)           Doctor B (Flutter)
──────────────────                 ───────────────────────────────            ──────────────────
user types message
    │
    ▼
supabase.from('consultation_messages')
  .insert({ session_id, sender_id,        ──────► PostgreSQL INSERT
            content, message_type })                    │
                                                        ▼
                                           supabase_realtime WAL listener
                                           (REPLICA IDENTITY FULL)
                                                        │
                                            WebSocket broadcast to all
                                            subscribers of this table+filter
                                                        │
                                                        ▼
                                           chatMessagesStreamProvider ◄────────── .stream(primaryKey:['id'])
                                             (StreamProvider.family)                .eq('session_id', sid)
                                                        │                           .order('created_at')
                                           setState → ListView rebuilds ◄──────────────────┘
```

### Flutter provider

```dart
final chatMessagesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, sessionId) {
  return supabase
      .from('consultation_messages')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('created_at', ascending: true)
      .map((rows) => List<Map<String, dynamic>>.from(rows));
});
```

`supabase.stream()` opens a persistent WebSocket channel. When any row is inserted/updated/deleted that matches the filter, the Stream emits a new list. The widget rebuilds automatically — no manual refresh.

### Required DB setup (both done in migrations 004 & 005)

| Requirement | SQL | Status |
|---|---|---|
| Table added to Realtime publication | `ALTER PUBLICATION supabase_realtime ADD TABLE consultation_messages;` | ✅ migration 004 |
| Full row payloads on UPDATE/DELETE | `ALTER TABLE consultation_messages REPLICA IDENTITY FULL;` | ✅ migration 004 |
| RLS SELECT allows members to read | Policy "Members view session messages" | ✅ migration 004 |

---

## 2. Bug Analysis — Why Chat Failed After Migration 004

Three independent bugs prevented chat from working.

### Bug 1 — RLS Chicken-and-Egg (PRIMARY — caused the error screen)

**Symptom:** "Could not open chat" immediately on entering any chat screen.

**Root cause:**  
`getOrCreateChatSession()` does:

```
1. INSERT INTO consultation_sessions (title, notes, created_by)
2. .select('id').single()   ← RLS SELECT runs here
3. INSERT INTO consultation_members (session_id, doctor_id × 2)
```

Migration 004 replaced the SELECT policy with:
```sql
CREATE POLICY "Doctors view consultation sessions" ON consultation_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM consultation_members cm
      JOIN doctors d ON d.id = cm.doctor_id
      WHERE cm.session_id = consultation_sessions.id
        AND d.profile_id = auth.uid()
    )
  );
```

At step 2, `consultation_members` is still empty — RLS returns 0 rows. `.single()` throws a `PostgrestException`. The error propagates to `chatSessionProvider`, which enters the error state, and the Flutter UI shows the hardcoded error message.

**Fix — migration 005:** Restore the `created_by IN (...)` OR branch:

```sql
DROP POLICY IF EXISTS "Doctors view consultation sessions" ON consultation_sessions;
CREATE POLICY "Doctors view consultation sessions" ON consultation_sessions
  FOR SELECT USING (
    created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM consultation_members cm
      JOIN doctors d ON d.id = cm.doctor_id
      WHERE cm.session_id = consultation_sessions.id
        AND d.profile_id = auth.uid()
    )
  );
```

---

### Bug 2 — `sender_id` FK Violation (would have broken message sending)

**Symptom:** Every `sendMessage()` call would fail with a PostgreSQL FK constraint violation.

**Root cause:**  
`consultation_messages.sender_id` is `FK → profiles.id` (the auth user's UUID).  
The Flutter code was passing `myDoctor.id` — the UUID from the `doctors` table — which is a completely different UUID.

```dart
// WRONG — doctors.id ≠ profiles.id
sendMessage(senderDoctorId: myDoctor.id, ...)

// Also wrong for isMe check
final isMe = msg['sender_id'] == myDoctorId;  // never true
```

**Fix — `doctor_chat_screen.dart`:**

```dart
// FIXED — use profiles.id (= auth UID)
sendMessage(senderDoctorId: supabase.auth.currentUser!.id, ...)

// FIXED — isMe uses the auth user's profile UUID
final isMe = msg['sender_id'] == supabase.auth.currentUser?.id;
```

This also applies to patient-share messages in `_showSharePatientSheet`.

---

### Bug 3 — Hardcoded Error Message (masked the real error)

**Symptom:** Error screen always showed the same "requires null patient_id" text regardless of the actual failure.

**Root cause:** The error message was written as a placeholder when the feature was scaffolded, before the DB migration existed. It was never updated to show the actual exception.

```dart
// BEFORE — static text, always shown on any error
Text('This feature requires the consultation_sessions table to allow null patient_id...')

// AFTER — shows the real Supabase/PostgreSQL error
Text(e.toString(), ...)
```

---

## 3. Do We Need a Third-Party Chat Service?

**No — for this feature set, Supabase Realtime is sufficient and free.**

| Capability | Supabase Realtime | Notes |
|---|---|---|
| Real-time message delivery | ✅ WebSocket push | Sub-second latency on same region |
| Message persistence | ✅ PostgreSQL | Durable, queryable, relational |
| Per-session filtering | ✅ `.eq('session_id', id)` | Only relevant messages delivered |
| RLS security | ✅ Row Level Security | Only session members receive/send |
| Free tier | ✅ 500 concurrent connections | Supabase free plan |
| Offline delivery / push notifications | ❌ Not built-in | Messages missed if app is closed |
| End-to-end encryption | ❌ Transit only (TLS) | Not E2EE |
| Video/audio calling | ❌ | ZEGOCLOUD already planned |

### When to consider a third party

| Scenario | Recommended option |
|---|---|
| Offline push notifications when app is closed | Add **Firebase Cloud Messaging (FCM)** as a companion (free tier generous) |
| Scale beyond 500 concurrent WebSocket connections | Upgrade Supabase plan OR evaluate **Stream Chat** (getstream.io, 5M msg/month free) |
| End-to-end encryption (regulatory requirement) | **Stream Chat** supports E2EE; also consider **Matrix/Element** (open source) |
| Rich features (reactions, threads, read receipts) | **Stream Chat** Flutter SDK is mature; free for < 100 MAU; paid trial available |
| Replace video calling (instead of ZEGOCLOUD) | **Daily.co** — generous free tier, WebRTC, Flutter-friendly |

**Recommendation for VoxMed:** Stay on Supabase Realtime + add FCM for offline push when Phase 9 (notifications) is implemented.

---

## 4. Migration Checklist

Both migrations must be applied in the **Supabase SQL Editor** for the chat to work.

### Step 1 — Migration 004 (if not yet applied)
File: `supabase/migrations/004_doctor_chat_realtime.sql`

- Makes `consultation_sessions.patient_id` nullable
- Makes `consultation_sessions.created_by` nullable  
- Adds `consultation_messages.message_type` column
- Adds prescriptions RLS for doctor INSERT
- Adds `consultation_messages` to Realtime publication
- Creates RLS policies for sessions, members, messages

### Step 2 — Migration 005 (new — fixes chicken-and-egg RLS)
File: `supabase/migrations/005_fix_chat_session_rls.sql`

- Fixes the `consultation_sessions` SELECT policy to allow the creator to read back their own session immediately after INSERT

### How to apply
1. Open https://supabase.com/dashboard → project `jedgnisrjwemhazherro`
2. Navigate to **SQL Editor → New query**
3. Paste and run migration 004, then 005

---

## 5. Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│  Flutter App (Doctor role)                                           │
│                                                                      │
│  CollaborativeHubScreen                                              │
│    └─ peerDoctorsProvider (FutureProvider)                           │
│         └─ CollaborationRepository.listPeerDoctors()                 │
│              └─ supabase.from('doctors').select(...)                 │
│                                                                      │
│  DoctorChatScreen                                                    │
│    ├─ chatSessionProvider (FutureProvider.family)                    │
│    │    └─ CollaborationRepository.getOrCreateChatSession()          │
│    │         ├─ SELECT consultation_members (find existing session)  │
│    │         ├─ INSERT consultation_sessions (new session)           │
│    │         ├─ SELECT consultation_sessions (read back session id)  │ ← Bug 1 was here
│    │         └─ INSERT consultation_members × 2                      │
│    │                                                                 │
│    └─ chatMessagesStreamProvider (StreamProvider.family)             │
│         └─ supabase.from('consultation_messages').stream(...)        │
│              └─ WebSocket channel ──► receives INSERT events live    │
│                                                                      │
│  sendMessage()                                                       │
│    └─ supabase.from('consultation_messages').insert({                │
│         session_id, sender_id: auth.currentUser.id,  ← Bug 2 fix   │
│         content, message_type                                        │
│       })                                                             │
└──────────────────────────────────────────────────────────────────────┘

                    ▲ WebSocket (Supabase Realtime)
                    │
┌───────────────────┴──────────────────────────────────────────────────┐
│  Supabase                                                            │
│                                                                      │
│  consultation_sessions  (patient_id nullable ✅ migration 004)       │
│  consultation_members                                                │
│  consultation_messages  (message_type column ✅, in Realtime pub ✅) │
│                                                                      │
│  RLS:                                                                │
│    sessions SELECT: created_by OR member  ← ✅ migration 005 fix    │
│    members SELECT/INSERT: doctor check                               │
│    messages SELECT: member check                                     │
│    messages INSERT: member check (no sender_id=auth.uid() needed)   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 6. Files Changed

| File | Change |
|---|---|
| `supabase/migrations/004_doctor_chat_realtime.sql` | Original migration (run by user) |
| `supabase/migrations/005_fix_chat_session_rls.sql` | **New** — fixes SELECT RLS chicken-and-egg |
| `lib/screens/doctor_chat_screen.dart` | 3 fixes: actual error display, sender_id uses auth UID, isMe uses auth UID |
| `docs/progress.md` | Phase 7 updated with bug fixes and action items |
| `docs/doctor_chat_realtime.md` | **New** — this document |
