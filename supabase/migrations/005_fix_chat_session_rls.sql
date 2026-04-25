-- ============================================================
-- Migration 005: Fix consultation_sessions SELECT RLS
-- Run in: Supabase SQL Editor → New Query
-- Project: jedgnisrjwemhazherro
-- ============================================================
--
-- Root-cause: Migration 004 replaced the SELECT policy for
-- consultation_sessions with one that only checks
-- consultation_members. But getOrCreateChatSession() inserts
-- the session first and then immediately reads it back
-- (.select('id').single()) BEFORE any members are inserted.
-- That SELECT hits an empty consultation_members table, RLS
-- returns 0 rows, .single() throws, and the chat screen shows
-- the hardcoded "Could not open chat" error even though the
-- INSERT itself succeeded.
--
-- Fix: restore the `created_by IN (...)` OR branch so the
-- creator can always read their own sessions.
-- ============================================================

DROP POLICY IF EXISTS "Doctors view consultation sessions" ON consultation_sessions;

CREATE POLICY "Doctors view consultation sessions" ON consultation_sessions
  FOR SELECT USING (
    -- The doctor who created the session can always see it
    -- (needed immediately after INSERT, before members are added)
    created_by IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
    OR
    -- Any doctor who is a member of the session can see it
    EXISTS (
      SELECT 1 FROM consultation_members cm
      JOIN doctors d ON d.id = cm.doctor_id
      WHERE cm.session_id = consultation_sessions.id
        AND d.profile_id = auth.uid()
    )
  );
