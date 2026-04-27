-- Migration 011 — Make adherence_logs.prescription_item_id nullable
-- The column was originally NOT NULL but seeds and direct schedule-based logging
-- (without a linked prescription item) need to insert rows without it.
-- Run this in Supabase SQL Editor before re-running the seed script.

ALTER TABLE adherence_logs
  ALTER COLUMN prescription_item_id DROP NOT NULL;
