-- ===============================================
-- Deadlines Table Setup
-- Run this in Supabase SQL Editor
-- ===============================================

-- Create deadlines table
CREATE TABLE IF NOT EXISTS deadlines (
  id BIGSERIAL PRIMARY KEY,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'assignment', -- 'assignment', 'project', 'exam', 'quiz', 'other'
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_deadlines_class ON deadlines(class_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_teacher ON deadlines(teacher_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON deadlines(due_date);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_deadlines_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_deadlines_timestamp
BEFORE UPDATE ON deadlines
FOR EACH ROW
EXECUTE FUNCTION update_deadlines_updated_at();

-- ===============================================
-- Verification Query
-- ===============================================
SELECT * FROM deadlines;
