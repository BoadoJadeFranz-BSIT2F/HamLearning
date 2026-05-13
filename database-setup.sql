-- ===============================================
-- HamLearning LMS Database Setup
-- Run this in Supabase SQL Editor
-- ===============================================

-- Add profile_picture column to users table (if not exists)
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture TEXT;

-- Add password reset columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP WITH TIME ZONE;

-- Create classes table
CREATE TABLE IF NOT EXISTS classes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  class_code TEXT UNIQUE NOT NULL,
  class_name TEXT NOT NULL,
  section TEXT NOT NULL,
  instructor_name TEXT NOT NULL,
  instructor_id UUID REFERENCES users(id),
  academic_year TEXT DEFAULT '2025',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create enrollments table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, class_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_enrollments_user ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_class ON enrollments(class_id);

-- ===============================================
-- Sample Data (Optional - for testing)
-- ===============================================

-- Insert sample classes
INSERT INTO classes (class_code, class_name, section, instructor_name, academic_year)
VALUES 
  ('DCIT25', 'Data Structures and Algorithms', 'BSIT-2C', 'Matella Loyla', '2025'),
  ('CS101', 'Introduction to Programming', 'BSCS-1A', 'John Doe', '2025'),
  ('MATH201', 'Calculus I', 'BSIT-2B', 'Jane Smith', '2025')
ON CONFLICT (class_code) DO NOTHING;

-- ===============================================
-- Verification Queries
-- ===============================================

-- Check classes table
SELECT * FROM classes;

-- Check enrollments table
SELECT * FROM enrollments;

-- View enrolled classes with details (after enrollments exist)
SELECT 
  e.id,
  e.enrolled_at,
  c.class_code,
  c.class_name,
  c.section,
  c.instructor_name,
  u.name as student_name,
  u.email as student_email
FROM enrollments e
JOIN classes c ON e.class_id = c.id
JOIN users u ON e.user_id = u.id
ORDER BY e.enrolled_at DESC;
