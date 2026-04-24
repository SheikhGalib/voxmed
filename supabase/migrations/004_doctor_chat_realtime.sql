-- ============================================================
-- Migration 004: Doctor-to-Doctor Chat + Realtime
-- Run in: Supabase SQL Editor → New Query
-- Project: jedgnisrjwemhazherro
-- ============================================================

-- ─── 1. consultation_sessions ─────────────────────────────────────────────────
-- patient_id is NOT NULL in the current schema, but doctor-to-doctor
-- chat sessions have no patient context. Make it nullable.
ALTER TABLE consultation_sessions
  ALTER COLUMN patient_id DROP NOT NULL;

-- created_by (doctors.id) was also NOT NULL but our insert omitted it.
-- Make it nullable so sessions can be created without a linked doctor row
-- (the code now passes created_by, but this guards against schema drift).
ALTER TABLE consultation_sessions
  ALTER COLUMN created_by DROP NOT NULL;


-- ─── 2. consultation_messages: add message_type ───────────────────────────────
-- Flutter sends message_type ('text' | 'patient_share') but the column
-- does not exist yet in the cloud schema.
ALTER TABLE consultation_messages
  ADD COLUMN IF NOT EXISTS message_type text NOT NULL DEFAULT 'text'
    CHECK (message_type IN ('text', 'patient_share'));


-- ─── 3. Prescriptions RLS — doctor INSERT ─────────────────────────────────────
-- Ensure doctors can write prescriptions for their own patients.
-- (The schema doc shows this policy but the cloud may be missing it.)
DROP POLICY IF EXISTS "Doctors insert own prescriptions" ON prescriptions;
CREATE POLICY "Doctors insert own prescriptions" ON prescriptions
  FOR INSERT WITH CHECK (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );


-- ─── 4. Enable Supabase Realtime on consultation_messages ─────────────────────
-- Adds the table to the supabase_realtime publication so Flutter's
-- .stream() / channel subscriptions receive live INSERT/UPDATE/DELETE events.
ALTER PUBLICATION supabase_realtime ADD TABLE consultation_messages;

-- REPLICA IDENTITY FULL makes UPDATE and DELETE payloads include the full
-- old row (needed if you ever want to detect edits/deletions client-side).
ALTER TABLE consultation_messages REPLICA IDENTITY FULL;


-- ─── 5. RLS policies for consultation_messages ────────────────────────────────
-- Doctors who are members of a session can read and write its messages.

DROP POLICY IF EXISTS "Members view session messages" ON consultation_messages;
CREATE POLICY "Members view session messages" ON consultation_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM consultation_members cm
      JOIN doctors d ON d.id = cm.doctor_id
      WHERE cm.session_id = consultation_messages.session_id
        AND d.profile_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Members insert session messages" ON consultation_messages;
CREATE POLICY "Members insert session messages" ON consultation_messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM consultation_members cm
      JOIN doctors d ON d.id = cm.doctor_id
      WHERE cm.session_id = consultation_messages.session_id
        AND d.profile_id = auth.uid()
    )
  );


-- ─── 6. RLS policies for consultation_sessions ────────────────────────────────
-- Recreate without the patient_id assumption so doctor-only sessions work.

DROP POLICY IF EXISTS "Doctors create consultation sessions" ON consultation_sessions;
CREATE POLICY "Doctors create consultation sessions" ON consultation_sessions
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM doctors WHERE profile_id = auth.uid())
  );

DROP POLICY IF EXISTS "Doctors view consultation sessions" ON consultation_sessions;
CREATE POLICY "Doctors view consultation sessions" ON consultation_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM consultation_members cm
      JOIN doctors d ON d.id = cm.doctor_id
      WHERE cm.session_id = consultation_sessions.id
        AND d.profile_id = auth.uid()
    )
  );


-- ─── 7. RLS for consultation_members ──────────────────────────────────────────
DROP POLICY IF EXISTS "Doctors insert members" ON consultation_members;
CREATE POLICY "Doctors insert members" ON consultation_members
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM doctors WHERE profile_id = auth.uid())
  );

DROP POLICY IF EXISTS "Doctors view associated members" ON consultation_members;
CREATE POLICY "Doctors view associated members" ON consultation_members
  FOR SELECT USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM consultation_sessions s
      WHERE s.id = consultation_members.session_id
        AND s.created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    )
  );
