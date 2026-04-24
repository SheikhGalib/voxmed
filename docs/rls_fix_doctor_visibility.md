# Doctor Approval — Bugs & Fixes

> **Last Updated:** 2026-04-24

---

## Fix 1 — RLS: Doctor Not Appearing for Hospital Approval

> **Date:** 2026-04-24  
> **Severity:** Critical — breaks the core doctor-approval workflow  
> **Status:** Applied — requires manual SQL execution in Supabase (migration `002_fix_rls_policies.sql`)

---

## Problem Statement

When a new doctor registers under a hospital via the Flutter mobile app, they **do not appear** in the hospital's doctor list on the web management dashboard for approval. Manually seeded doctors appear correctly. Newly registered doctors are invisible.

---

## Root Cause Analysis

### The database is shared

Both the **Flutter app** (voxmed) and the **React web dashboard** (voxmedweb) use the same Supabase project. They have different access patterns:

| Client | Key Used | RLS |
|---|---|---|
| Flutter app | `anon` / user JWT | **Enforced** |
| Web backend (Node/Express) | `service_role` | **Bypassed** |

This asymmetry is the origin of the bug.

### Problem 1 — Silent INSERT failure (critical)

The `doctors` table has these RLS policies:

```sql
-- Only approved doctors are publicly visible
CREATE POLICY "Public can view approved doctors"
  ON doctors FOR SELECT USING (status = 'approved');

-- Service role has full access (web dashboard)
CREATE POLICY "Service role full access doctors"
  ON doctors FOR ALL USING (auth.role() = 'service_role');
```

There is **no INSERT policy for `authenticated` users**.

When the Flutter app's `DoctorRepository` calls:

```dart
await supabase.from('doctors').insert({
  'profile_id': userId,
  'hospital_id': selectedHospitalId,
  'specialty': specialty,
  // ...
});
```

Supabase evaluates the INSERT against RLS policies. Because no `INSERT TO authenticated` policy exists, the insert is **silently denied** — Supabase returns an empty result with no error. The doctor row is never written to the database.

Since no row exists, the hospital admin's dashboard query (which runs with service_role) correctly returns zero rows for that doctor.

### Problem 2 — Doctor cannot see own pending profile (secondary)

The only `SELECT` policy filters `status = 'approved'`. A newly registered doctor (with `status = 'pending'`) cannot query their own row from the Flutter app. This means:

- The doctor dashboard cannot display "your profile is under review"
- Any profile-loading code will return null for pending doctors
- The doctor's own data is invisible to them until the hospital approves them

### Why seeded data works

The seed script (`server/scripts/seed-data.js`) uses the **service_role key** (via `supabaseAdmin` client), which bypasses RLS entirely. Seeded rows are inserted regardless of any INSERT policies. This is why the seeded doctors appear but newly self-registered doctors do not.

---

## Fix

Apply the SQL in `supabase/migrations/002_fix_rls_policies.sql`.

### How to apply

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project (`jedgnisrjwemhazherro`)
2. Navigate to **SQL Editor** → **New query**
3. Paste the contents of `voxmedweb/supabase/migrations/002_fix_rls_policies.sql`
4. Click **Run**

### What the migration adds

```sql
-- Fix 1: Allow doctor to INSERT their own row
CREATE POLICY "Doctors can insert own profile"
  ON public.doctors FOR INSERT TO authenticated
  WITH CHECK (profile_id = auth.uid());

-- Fix 2: Allow doctor to SELECT their own row (even when pending)
CREATE POLICY "Doctors can view own profile"
  ON public.doctors FOR SELECT TO authenticated
  USING (profile_id = auth.uid());

-- Fix 3: Allow hospital admin to SELECT all their hospital's doctors
CREATE POLICY "Hospital admin views own hospital doctors"
  ON public.doctors FOR SELECT TO authenticated
  USING (
    hospital_id IN (
      SELECT hs.hospital_id FROM public.hospital_staff hs
      WHERE hs.profile_id = auth.uid()
        AND hs.role = 'admin'  -- hospital_role enum: admin | receptionist | lab
    )
  );
```

### Why Fix 3 is defence-in-depth

The web dashboard already bypasses RLS via `service_role`, so Fix 3 is not strictly required for the current web app to work. However, it is included so that:

- Any future Flutter-side hospital admin views will work correctly
- The security model is explicit and auditable — instead of relying on the implicit "service_role bypasses everything" behaviour

---

## After Applying the Fix

### Expected behaviour

| Action | Before Fix | After Fix |
|---|---|---|
| Doctor registers in Flutter app | Row silently not created | Row created with `status = 'pending'` |
| Doctor opens their profile in app | null / empty | Shows profile with pending status badge |
| Hospital admin opens web dashboard | Doctor not listed | Doctor appears in Pending tab |
| Hospital admin approves doctor | n/a | Sets `status = 'approved'`, `approved_by_hospital = true`, `is_available = true` |
| Patient searches for doctors | n/a | Approved doctor appears in directory |

### Verification query (run in Supabase SQL Editor)

```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'doctors'
ORDER BY policyname;
```

Expected output after migration:

| policyname | cmd |
|---|---|
| Doctors can insert own profile | INSERT |
| Doctors can view own profile | SELECT |
| Hospital admin views own hospital doctors | SELECT |
| Public can view approved doctors | SELECT |
| Service role full access doctors | ALL |

---

## Affected Files

| File | Change |
|---|---|
| `voxmedweb/supabase/migrations/002_fix_rls_policies.sql` | New migration — apply in Supabase SQL Editor |
| `voxmed/docs/database_schema.md` | Updated RLS section to document actual + required policies |
| `voxmedweb/supabase/schema.sql` | Reference schema (not executed); reflects same issue |

---

## Related Architecture Notes

- The `public_doctors` view (added in migration `001`) already correctly filters for `status = 'approved' AND approved_by_hospital = true AND is_available = true`. Once this fix is applied and a doctor is approved, they will automatically appear in this view for the patient-facing Flutter app.
- The `hospital_staff` table stores hospital admins with `role = 'admin'` (not `'hospital_admin'`) in the current seed data. The hospital_role enum values are: `admin`, `receptionist`, `lab`.

---

## Fix 2 — Flutter: Approval Status Not Refreshing After Sign-Out/Sign-In

> **Date:** 2026-04-24  
> **Severity:** High — doctor sees stale "Approval Pending" screen after sign-in even when approved  
> **Status:** Fixed in `lib/providers/doctor_provider.dart`

### Symptom

After the hospital admin approves a doctor on the web dashboard, the doctor signs out and signs back in on the Flutter app. The app still shows "Approval Pending". Only a full app restart (cold start) shows the correct approved dashboard.

### Root Cause

`currentDoctorProvider` was a plain `FutureProvider` that directly read `supabase.auth.currentUser?.id`. It had no dependency on auth state:

```dart
// BEFORE (buggy)
final currentDoctorProvider = FutureProvider<Doctor?>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;
  return ref.read(doctorRepositoryProvider).getDoctorByProfileId(userId);
});
```

Riverpod caches `FutureProvider` values. When the user signs out and signs back in:
1. GoRouter's `_authRefreshListenable` fires (it watches `onAuthStateChange`)
2. The router redirects back to `clinicalDashboard`
3. `ClinicalDashboardScreen` calls `ref.watch(currentDoctorProvider)`
4. Riverpod returns the **stale cached value** (still `status = 'pending'`)
5. The "Approval Pending" screen renders again

On a cold restart, Riverpod starts with no cache, so the provider re-fetches and gets the updated `status = 'approved'`.

### Fix

`currentDoctorProvider` now watches `authStateProvider`. Riverpod tracks this dependency and automatically invalidates + re-runs the provider whenever the auth state changes (sign-in, sign-out, token refresh):

```dart
// AFTER (fixed)
final currentDoctorProvider = FutureProvider<Doctor?>((ref) async {
  // Depend on auth state — provider auto-invalidates when session changes.
  final authState = await ref.watch(authStateProvider.future);
  if (authState.session == null) return null;
  final userId = authState.session!.user.id;
  return ref.read(doctorRepositoryProvider).getDoctorByProfileId(userId);
});
```

### File Changed

- `voxmed/lib/providers/doctor_provider.dart`

---

## Fix 3 — Web: Schedule Save Fails with "is_available column not found"

> **Date:** 2026-04-24  
> **Severity:** High — hospital admin cannot set any doctor schedule  
> **Status:** Fixed in `server/src/routes/hospital/doctors.js`

### Symptom

When a hospital admin opens the Schedule dialog for an approved doctor and clicks "Save Schedule", a browser alert shows:

> Could not find the 'is_available' column of 'doctor_schedules' in the schema cache

### Root Cause

The cloud `doctor_schedules` table uses `is_active` for the availability boolean:

```sql
CREATE TABLE public.doctor_schedules (
  ...
  is_active boolean DEFAULT true,  -- actual column name
  ...
);
```

But the server's Zod validation schema used `is_available` — a name carried over from an earlier design:

```js
// BEFORE (buggy)
const scheduleSchema = z.object({
  day_of_week: z.number().min(0).max(6),
  start_time: z.string(),
  end_time: z.string(),
  max_patients: z.number().min(1).default(20),
  is_available: z.boolean().default(true),  // wrong column name
});
```

When the validated payload was spread into the Supabase upsert (`{ doctor_id, ...req.validated }`), it included `is_available` which does not exist in the table, causing PostgREST to reject the request.

### Fix

Renamed `is_available` → `is_active` in the Zod schema to match the actual column:

```js
// AFTER (fixed)
const scheduleSchema = z.object({
  day_of_week: z.number().min(0).max(6),
  start_time: z.string(),
  end_time: z.string(),
  max_patients: z.number().min(1).default(20),  // ← still wrong, see Fix 4
  is_active: z.boolean().default(true),          // ← correct column name
});
```

No client-side changes needed for this field specifically.

### File Changed

- `voxmedweb/server/src/routes/hospital/doctors.js`

---

## Fix 4 — Web: Schedule Save Fails with "max_patients column not found"

> **Date:** 2026-04-24  
> **Severity:** High — hospital admin cannot set any doctor schedule  
> **Status:** Fixed in `server/src/routes/hospital/doctors.js` and `client/src/pages/hospital/HospitalDoctors.jsx`

### Symptom

After Fix 3 resolved the `is_available` error, a new alert appeared when saving a doctor schedule:

> Could not find the 'max_patients' column of 'doctor_schedules' in the schema cache

### Root Cause

The local reference schema (`voxmedweb/supabase/schema.sql`) defined `doctor_schedules` with a `max_patients` column, but the actual cloud table was created with `slot_duration_minutes` instead:

**Actual cloud columns (verified via REST API):**
```json
{"id", "doctor_id", "day_of_week", "start_time", "end_time", "slot_duration_minutes", "is_active", "created_at"}
```

The server's Zod schema and the client form both used `max_patients`, which Supabase rejected because the column doesn't exist.

### Fix

**Server** (`voxmedweb/server/src/routes/hospital/doctors.js`) — replaced `max_patients` with `slot_duration_minutes` in `scheduleSchema`:

```js
// BEFORE
const scheduleSchema = z.object({
  ...
  max_patients: z.number().min(1).default(20),
  is_active: z.boolean().default(true),
});

// AFTER
const scheduleSchema = z.object({
  ...
  slot_duration_minutes: z.number().min(5).default(30),
  is_active: z.boolean().default(true),
});
```

**Client form** (`voxmedweb/client/src/pages/hospital/HospitalDoctors.jsx`) — updated initial state, submission payload, and form input label:

```js
// BEFORE
const [scheduleForm, setScheduleForm] = useState({ ..., max_patients: 20 });
// form sends: max_patients: parseInt(scheduleForm.max_patients)
// label: "Max Patients"

// AFTER
const [scheduleForm, setScheduleForm] = useState({ ..., slot_duration_minutes: 30 });
// form sends: slot_duration_minutes: parseInt(scheduleForm.slot_duration_minutes)
// label: "Slot Duration (minutes)"
```

**Receptionist view** (`voxmedweb/client/src/pages/receptionist/ReceptionistSchedules.jsx`) — updated column header and cell to display `slot_duration_minutes`:

```jsx
// BEFORE
<TableHead>Max Patients</TableHead>
<TableCell>{s.max_patients}</TableCell>

// AFTER
<TableHead>Slot (min)</TableHead>
<TableCell>{s.slot_duration_minutes} min</TableCell>
```

### How to Spot This Class of Bug

When a local `schema.sql` differs from the actual cloud schema, any field sent in a Supabase upsert/insert that doesn't exist in the live table will produce:

> `Could not find the '<field>' column of '<table>' in the schema cache`

**Always verify column names against the live cloud data** — the reference schema file is not authoritative. Use a REST API call with the service role key:

```powershell
$h = @{ "apikey" = "<service_role_key>"; "Authorization" = "Bearer <service_role_key>" }
Invoke-RestMethod -Uri "https://<project>.supabase.co/rest/v1/<table>?limit=1" -Headers $h
```

### Files Changed

- `voxmedweb/server/src/routes/hospital/doctors.js`
- `voxmedweb/client/src/pages/hospital/HospitalDoctors.jsx`
- `voxmedweb/client/src/pages/receptionist/ReceptionistSchedules.jsx`


