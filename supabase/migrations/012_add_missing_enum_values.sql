-- Migration 012: Add missing enum values
-- Adds follow_up to renewal_status and renewal_follow_up + appointment_completed to notification_type

ALTER TYPE renewal_status ADD VALUE IF NOT EXISTS 'follow_up';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'renewal_follow_up';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'appointment_completed';
