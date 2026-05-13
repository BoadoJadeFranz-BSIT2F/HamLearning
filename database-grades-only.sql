-- ===============================================
-- Grades Table Setup (Quick Start)
-- Run this in Supabase SQL Editor first
-- ===============================================

-- Create grades table (for student manual entries)
CREATE TABLE IF NOT EXISTS grades (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,  -- Can be NULL for subject-based entries
  title TEXT NOT NULL,
  score DECIMAL(5,2) NOT NULL,
  max_score DECIMAL(5,2) NOT NULL,
  type TEXT NOT NULL, -- 'quiz', 'exam', 'assignment', 'project', 'other'
  date_taken TIMESTAMP WITH TIME ZONE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_grades_user_id ON grades(user_id);
CREATE INDEX IF NOT EXISTS idx_grades_class_id ON grades(class_id);
CREATE INDEX IF NOT EXISTS idx_grades_date_taken ON grades(date_taken);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_grades_updated_at
  BEFORE UPDATE ON grades
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (adjust based on your RLS policies)
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own grades
CREATE POLICY "Users can view their own grades"
  ON grades FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert their own grades
CREATE POLICY "Users can insert their own grades"
  ON grades FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own grades
CREATE POLICY "Users can update their own grades"
  ON grades FOR UPDATE
  USING (auth.uid() = user_id);

-- Allow users to delete their own grades
CREATE POLICY "Users can delete their own grades"
  ON grades FOR DELETE
  USING (auth.uid() = user_id);
