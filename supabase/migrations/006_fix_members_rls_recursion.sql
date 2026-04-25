-- ============================================================
-- Migration 006: Fix infinite recursion in consultation_members RLS
-- Run in: Supabase SQL Editor → New Query
-- Project: jedgnisrjwemhazherro
-- ============================================================
--
-- Root-cause:
-- The consultation_members SELECT policy (migration 004) has a
-- second OR branch that references consultation_sessions:
--
--   OR EXISTS (
--     SELECT 1 FROM consultation_sessions s
--     WHERE s.id = consultation_members.session_id
--       AND s.created_by IN (SELECT id FROM doctors WHERE ...)
--   )
--
-- The consultation_sessions SELECT policy (migration 005) in turn
-- has a branch that references consultation_members:
--
--   OR EXISTS (
--     SELECT 1 FROM consultation_members cm
--     JOIN doctors d ON d.id = cm.doctor_id
--     WHERE cm.session_id = consultation_sessions.id ...
--   )
--
-- PostgreSQL evaluates both policies whenever either table is
-- queried. Each policy causes the other table to be queried,
-- which triggers its policy, which queries back — infinite loop.
-- PostgreSQL raises 42P17: "infinite recursion detected in policy".
--
-- Fix:
-- Remove the consultation_sessions reference from the
-- consultation_members SELECT policy. The first branch
-- (doctor_id IN ...) is sufficient: getOrCreateChatSession()
-- always inserts the creator as a member, so any doctor who
-- needs to read consultation_members will always match on
-- their own doctor_id row.
-- ============================================================

DROP POLICY IF EXISTS "Doctors view associated members" ON consultation_members;

CREATE POLICY "Doctors view associated members" ON consultation_members
  FOR SELECT USING (
    -- A doctor can see membership rows where they are the member.
    -- Non-recursive: does NOT reference consultation_sessions.
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );
