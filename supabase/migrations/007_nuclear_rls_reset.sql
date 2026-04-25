-- ============================================================
-- Migration 007: Nuclear RLS reset for consultation tables
-- Run in: Supabase SQL Editor → New Query
-- Project: jedgnisrjwemhazherro
-- ============================================================
--
-- Why this migration exists:
-- Migrations 004–006 left residual cross-table references in
-- the consultation_members SELECT policy. The cycle:
--   sessions_select → consultation_members (triggers members_select)
--   members_select  → consultation_sessions (triggers sessions_select)
-- causes PostgreSQL error 42P17 (infinite recursion).
--
-- Approach — SECURITY DEFINER helper:
-- get_my_doctor_id() resolves auth.uid() → doctors.id OUTSIDE
-- the RLS evaluation context. Because it is SECURITY DEFINER it
-- runs as the function owner and never triggers another RLS
-- policy. Every policy below calls this function instead of
-- inline subqueries that cross-reference the other tables.
-- Dependency tree (one-way, no cycles):
--   sessions_select  → consultation_members (safe: members_select is self-contained)
--   members_select   → (nothing — pure equality check)
--   messages_select  → consultation_members (same as above)
--   messages_insert  → consultation_members (same as above)
--
-- Ambiguities fixed vs. the original draft:
--   1. sessions_insert: changed from `get_my_doctor_id() IS NOT NULL`
--      to `created_by = get_my_doctor_id()` — enforces that the
--      doctor can only create sessions where they are the creator.
--      Prevents inserting a session with another doctor's UUID in
--      the created_by field.
--   2. messages_insert: added `sender_id = auth.uid()` guard —
--      prevents a session member from spoofing another doctor's
--      sender identity in the message row.
-- ============================================================


-- ─── Step 1: Drop ALL policies on the 3 affected tables ──────────────────────
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE tablename IN (
      'consultation_sessions',
      'consultation_members',
      'consultation_messages'
    )
    AND schemaname = 'public'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I',
      r.policyname,
      r.tablename
    );
  END LOOP;
END
$$;


-- ─── Step 2: SECURITY DEFINER helper ─────────────────────────────────────────
-- Resolves the current user's doctors.id without triggering any
-- RLS policy. All policies below use this instead of inline
-- subqueries that reference doctors — keeping every policy
-- self-contained and non-recursive.
CREATE OR REPLACE FUNCTION get_my_doctor_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM doctors WHERE profile_id = auth.uid() LIMIT 1;
$$;


-- ─── Step 3: consultation_sessions ───────────────────────────────────────────
-- sessions_select references consultation_members (one-way).
-- members_select does NOT reference consultation_sessions → no cycle.

CREATE POLICY "sessions_select" ON consultation_sessions
  FOR SELECT USING (
    created_by = get_my_doctor_id()
    OR id IN (
      SELECT session_id FROM consultation_members
      WHERE doctor_id = get_my_doctor_id()
    )
  );

-- FIX #1: enforce created_by = the requesting doctor, not just
-- any authenticated doctor. Prevents created_by spoofing.
CREATE POLICY "sessions_insert" ON consultation_sessions
  FOR INSERT WITH CHECK (
    created_by = get_my_doctor_id()
  );


-- ─── Step 4: consultation_members ────────────────────────────────────────────
-- CRITICAL: must NOT reference consultation_sessions at all.
-- (sessions_select → members is fine; members → sessions → members = loop)

CREATE POLICY "members_select" ON consultation_members
  FOR SELECT USING (
    doctor_id = get_my_doctor_id()
  );

-- Any authenticated doctor can add members (both sides of the
-- chat are inserted by getOrCreateChatSession immediately).
CREATE POLICY "members_insert" ON consultation_members
  FOR INSERT WITH CHECK (
    get_my_doctor_id() IS NOT NULL
  );


-- ─── Step 5: consultation_messages ───────────────────────────────────────────
-- messages_select/insert reference consultation_members (one-way).
-- members_select is self-contained → no cycle.

CREATE POLICY "messages_select" ON consultation_messages
  FOR SELECT USING (
    session_id IN (
      SELECT session_id FROM consultation_members
      WHERE doctor_id = get_my_doctor_id()
    )
  );

-- FIX #2: add sender_id = auth.uid() guard so a session member
-- cannot insert a message that claims to be from another doctor.
-- auth.uid() == profiles.id == consultation_messages.sender_id FK target.
CREATE POLICY "messages_insert" ON consultation_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND session_id IN (
      SELECT session_id FROM consultation_members
      WHERE doctor_id = get_my_doctor_id()
    )
  );
