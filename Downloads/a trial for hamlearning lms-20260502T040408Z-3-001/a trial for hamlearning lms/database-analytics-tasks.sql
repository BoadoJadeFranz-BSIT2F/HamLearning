-- ===============================================
-- Analytics & Tasks Database Setup
-- Run this in Supabase SQL Editor
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

-- Create tasks table (both teacher-created and student personal tasks)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES users(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL, -- 'teacher' or 'personal'
  due_date TIMESTAMP WITH TIME ZONE,
  max_score DECIMAL(5,2), -- Only for teacher tasks
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Either teacher_id OR student_id should be set, not both
  CHECK (
    (type = 'teacher' AND teacher_id IS NOT NULL AND student_id IS NULL) OR
    (type = 'personal' AND student_id IS NOT NULL AND teacher_id IS NULL)
  )
);

-- Create task submissions table (for file uploads and scores)
CREATE TABLE IF NOT EXISTS task_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  file_url TEXT,
  file_name TEXT,
  submission_text TEXT,
  score DECIMAL(5,2),
  feedback TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  graded_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(task_id, student_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_grades_user ON grades(user_id);
CREATE INDEX IF NOT EXISTS idx_grades_class ON grades(class_id);
CREATE INDEX IF NOT EXISTS idx_grades_date ON grades(date_taken);

CREATE INDEX IF NOT EXISTS idx_tasks_class ON tasks(class_id);
CREATE INDEX IF NOT EXISTS idx_tasks_teacher ON tasks(teacher_id);
CREATE INDEX IF NOT EXISTS idx_tasks_student ON tasks(student_id);
CREATE INDEX IF NOT EXISTS idx_tasks_type ON tasks(type);

CREATE INDEX IF NOT EXISTS idx_submissions_task ON task_submissions(task_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON task_submissions(student_id);

-- Create triggers to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_grades_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_grades_timestamp
BEFORE UPDATE ON grades
FOR EACH ROW
EXECUTE FUNCTION update_grades_updated_at();

CREATE OR REPLACE FUNCTION update_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tasks_timestamp
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_tasks_updated_at();

CREATE OR REPLACE FUNCTION update_task_submissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_submissions_timestamp
BEFORE UPDATE ON task_submissions
FOR EACH ROW
EXECUTE FUNCTION update_task_submissions_updated_at();

-- ===============================================
-- Verification Queries
-- ===============================================
SELECT * FROM grades;
SELECT * FROM tasks;
SELECT * FROM task_submissions;
