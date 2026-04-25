-- ============================================================
-- Migration 008: Deduplicate consultation_sessions + UNIQUE title
-- Run in: Supabase SQL Editor → New Query
-- Project: jedgnisrjwemhazherro
-- ============================================================
--
-- Why this migration exists:
-- The old getOrCreateChatSession() used a cross-membership lookup
-- that always returned 0 rows (RLS members_select only exposes
-- your OWN rows). As a result, every time any doctor opened a
-- chat a new session was created, producing duplicate sessions
-- for the same doctor pair and breaking message persistence.
--
-- This migration:
--   1. Removes duplicate dr_chat sessions — keeps the oldest one
--      per (sorted) doctor pair and deletes the rest (cascades to
--      consultation_members and consultation_messages).
--   2. Adds a UNIQUE constraint on consultation_sessions.title
--      so this can never happen again, even under a race condition.
-- ============================================================


-- ─── Step 1: Delete duplicate dr_chat sessions ───────────────────────────────
-- For each unique title, keep the row with the smallest created_at
-- (the original session), delete all later duplicates.
-- ON DELETE CASCADE on consultation_members and consultation_messages
-- handles the child rows automatically.
DELETE FROM consultation_sessions
WHERE title LIKE 'dr_chat:%'
  AND id NOT IN (
    SELECT DISTINCT ON (title) id
    FROM consultation_sessions
    WHERE title LIKE 'dr_chat:%'
    ORDER BY title, created_at ASC
  );


-- ─── Step 2: Add UNIQUE constraint on title ──────────────────────────────────
-- Prevents duplicate sessions for the same doctor pair in future,
-- even if two doctors open the chat simultaneously.
-- NULL titles are excluded (UNIQUE does not apply to NULL values in PostgreSQL).
ALTER TABLE consultation_sessions
  ADD CONSTRAINT consultation_sessions_title_unique UNIQUE (title);
