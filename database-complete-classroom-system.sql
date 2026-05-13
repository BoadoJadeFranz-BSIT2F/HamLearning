-- ===============================================
-- COMPLETE GOOGLE CLASSROOM-STYLE DATABASE SETUP
-- Run this entire file in Supabase SQL Editor
-- ===============================================

-- ===============================================
-- 1. ENROLLMENTS TABLE (Student-Class Relationship)
-- ===============================================
DROP TABLE IF EXISTS enrollments CASCADE;

CREATE TABLE enrollments (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add unique constraint to prevent duplicate enrollments
ALTER TABLE enrollments ADD CONSTRAINT unique_user_class UNIQUE (user_id, class_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_enrollments_user_id ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_class_id ON enrollments(class_id);

-- Disable RLS
ALTER TABLE enrollments DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 2. DEADLINES TABLE (Teacher creates assignments/tasks)
-- ===============================================
DROP TABLE IF EXISTS deadlines CASCADE;

CREATE TABLE deadlines (
  id BIGSERIAL PRIMARY KEY,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instructions TEXT,
  type TEXT NOT NULL DEFAULT 'assignment', -- 'assignment', 'project', 'exam', 'quiz', 'material', 'announcement'
  due_date TIMESTAMP WITH TIME ZONE,
  points INTEGER DEFAULT 100,
  allow_late_submission BOOLEAN DEFAULT true,
  submission_type TEXT DEFAULT 'file', -- 'file', 'text', 'link', 'none'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_deadlines_class ON deadlines(class_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_teacher ON deadlines(teacher_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON deadlines(due_date);
CREATE INDEX IF NOT EXISTS idx_deadlines_type ON deadlines(type);

-- Disable RLS
ALTER TABLE deadlines DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 3. DEADLINE_FILES TABLE (Materials attached by teacher)
-- ===============================================
DROP TABLE IF EXISTS deadline_files CASCADE;

CREATE TABLE deadline_files (
  id BIGSERIAL PRIMARY KEY,
  deadline_id BIGINT NOT NULL REFERENCES deadlines(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_deadline_files_deadline ON deadline_files(deadline_id);

-- Disable RLS
ALTER TABLE deadline_files DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 4. SUBMISSIONS TABLE (Student submits work)
-- ===============================================
DROP TABLE IF EXISTS submissions CASCADE;

CREATE TABLE submissions (
  id BIGSERIAL PRIMARY KEY,
  deadline_id BIGINT NOT NULL REFERENCES deadlines(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'assigned', -- 'assigned', 'turned_in', 'graded', 'returned'
  submission_text TEXT,
  submission_link TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE,
  is_late BOOLEAN DEFAULT false,
  grade INTEGER,
  feedback TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(deadline_id, student_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_submissions_deadline ON submissions(deadline_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);

-- Disable RLS
ALTER TABLE submissions DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 5. SUBMISSION_FILES TABLE (Files uploaded by student)
-- ===============================================
DROP TABLE IF EXISTS submission_files CASCADE;

CREATE TABLE submission_files (
  id BIGSERIAL PRIMARY KEY,
  submission_id BIGINT NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_submission_files_submission ON submission_files(submission_id);

-- Disable RLS
ALTER TABLE submission_files DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 6. CLASS_FILES TABLE (Reference materials - feed only)
-- ===============================================
-- Keep existing class_files but use it only for non-deadline posts
-- This table already exists, just ensure it has proper structure

-- If class_files doesn't exist, create it:
CREATE TABLE IF NOT EXISTS class_files (
  id BIGSERIAL PRIMARY KEY,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_class_files_class ON class_files(class_id);
CREATE INDEX IF NOT EXISTS idx_class_files_teacher ON class_files(teacher_id);

-- Disable RLS
ALTER TABLE class_files DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 7. FILE_COMMENTS TABLE (Comments on files/materials)
-- ===============================================
DROP TABLE IF EXISTS file_comments CASCADE;

CREATE TABLE file_comments (
    id BIGSERIAL PRIMARY KEY,
    file_id BIGINT REFERENCES class_files(id) ON DELETE CASCADE,
    deadline_id BIGINT REFERENCES deadlines(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (file_id IS NOT NULL OR deadline_id IS NOT NULL)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_file_comments_file_id ON file_comments(file_id);
CREATE INDEX IF NOT EXISTS idx_file_comments_deadline_id ON file_comments(deadline_id);
CREATE INDEX IF NOT EXISTS idx_file_comments_user_id ON file_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_file_comments_created_at ON file_comments(created_at DESC);

-- Disable RLS
ALTER TABLE file_comments DISABLE ROW LEVEL SECURITY;


-- ===============================================
-- 8. TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- ===============================================

-- Deadlines trigger
CREATE OR REPLACE FUNCTION update_deadlines_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_deadlines_timestamp ON deadlines;
CREATE TRIGGER trigger_update_deadlines_timestamp
BEFORE UPDATE ON deadlines
FOR EACH ROW
EXECUTE FUNCTION update_deadlines_updated_at();

-- Submissions trigger
CREATE OR REPLACE FUNCTION update_submissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_submissions_timestamp ON submissions;
CREATE TRIGGER trigger_update_submissions_timestamp
BEFORE UPDATE ON submissions
FOR EACH ROW
EXECUTE FUNCTION update_submissions_updated_at();


-- ===============================================
-- 9. AUTO-CREATE SUBMISSIONS WHEN DEADLINE IS POSTED
-- ===============================================

-- Function to create submissions for all enrolled students
CREATE OR REPLACE FUNCTION create_submissions_for_deadline()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create submissions for assignment-type deadlines
  IF NEW.type IN ('assignment', 'project', 'exam', 'quiz') THEN
    INSERT INTO submissions (deadline_id, student_id, status, is_late)
    SELECT 
      NEW.id,
      e.user_id,
      'assigned',
      false
    FROM enrollments e
    WHERE e.class_id = NEW.class_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_submissions ON deadlines;
CREATE TRIGGER trigger_create_submissions
AFTER INSERT ON deadlines
FOR EACH ROW
EXECUTE FUNCTION create_submissions_for_deadline();


-- ===============================================
-- 10. AUTO-UPDATE is_late WHEN STUDENT SUBMITS
-- ===============================================

CREATE OR REPLACE FUNCTION check_late_submission()
RETURNS TRIGGER AS $$
DECLARE
  deadline_date TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get the deadline's due_date
  SELECT due_date INTO deadline_date
  FROM deadlines
  WHERE id = NEW.deadline_id;
  
  -- If submitting and there's a due date
  IF NEW.status = 'turned_in' AND NEW.submitted_at IS NOT NULL AND deadline_date IS NOT NULL THEN
    -- Check if submitted after deadline
    NEW.is_late := NEW.submitted_at > deadline_date;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_late_submission ON submissions;
CREATE TRIGGER trigger_check_late_submission
BEFORE UPDATE ON submissions
FOR EACH ROW
WHEN (NEW.status = 'turned_in' AND NEW.submitted_at IS NOT NULL)
EXECUTE FUNCTION check_late_submission();


-- ===============================================
-- 11. VERIFICATION QUERIES
-- ===============================================

-- Check all tables exist
SELECT 'enrollments' as table_name, COUNT(*) as rows FROM enrollments
UNION ALL
SELECT 'deadlines', COUNT(*) FROM deadlines
UNION ALL
SELECT 'deadline_files', COUNT(*) FROM deadline_files
UNION ALL
SELECT 'submissions', COUNT(*) FROM submissions
UNION ALL
SELECT 'submission_files', COUNT(*) FROM submission_files
UNION ALL
SELECT 'class_files', COUNT(*) FROM class_files
UNION ALL
SELECT 'file_comments', COUNT(*) FROM file_comments;


-- ===============================================
-- NOTES FOR IMPLEMENTATION
-- ===============================================

/*
TEACHER WORKFLOW:
1. Teacher creates a deadline (assignment/project/quiz) in "Deadlines" section
2. Teacher can attach files to the deadline (stored in deadline_files)
3. System auto-creates submissions for all enrolled students (status: 'assigned')
4. Deadline appears in student's "Deadlines" feed with attached materials

STUDENT WORKFLOW:
1. Student sees deadline in their dashboard (from submissions table)
2. Student can download teacher's attached files (deadline_files)
3. Student uploads their work files (submission_files) or adds text/link
4. Student clicks "Turn In" → status changes to 'turned_in', submitted_at set
5. System automatically checks if late based on due_date vs submitted_at
6. Teacher can view submissions, grade, and provide feedback

STATUS FLOW:
- assigned → turned_in → graded → returned
- assigned → (not submitted) → missing (if past due date)

FILES ORGANIZATION:
- deadline_files/: Teacher's instruction materials
- submission_files/: Student's submitted work
- class_files/: General reference materials (no submission required)
*/
