-- ===============================================
-- SAFE ARCHIVE + NORMALIZATION MIGRATION (NON-DESTRUCTIVE)
-- For Supabase SQL Editor
-- ===============================================
-- This script is additive and safe: it does NOT drop existing tables.
-- It aligns schema used by the archive + class/deadline/material features.

BEGIN;

-- -----------------------------------------------
-- 1) Core table sanity for classes/deadlines/files
-- -----------------------------------------------
ALTER TABLE classes
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE deadlines
  ADD COLUMN IF NOT EXISTS instructions TEXT,
  ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS allow_late_submission BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS submission_type TEXT DEFAULT 'file',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE class_files
  ADD COLUMN IF NOT EXISTS upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE file_comments
  ADD COLUMN IF NOT EXISTS deadline_id BIGINT REFERENCES deadlines(id) ON DELETE CASCADE;

-- -----------------------------------------------
-- 2) Archive table (normalized + shared)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS archive_items (
  id BIGSERIAL PRIMARY KEY,
  archive_key TEXT NOT NULL UNIQUE,
  scope TEXT NOT NULL DEFAULT 'class', -- class | personal
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL,           -- class | deadline | deadline_attachment | class_file | personal_task | ...
  source_id TEXT NOT NULL,
  class_id BIGINT REFERENCES classes(id) ON DELETE CASCADE,
  class_name TEXT,
  deadline_id BIGINT REFERENCES deadlines(id) ON DELETE CASCADE,
  deadline_title TEXT,
  title TEXT NOT NULL,
  description TEXT,
  file_name TEXT,
  file_type TEXT,
  file_size BIGINT,
  file_url TEXT,
  file_path TEXT,
  archived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optional check constraint for scope values (non-restrictive to roles)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'archive_items_scope_check'
  ) THEN
    ALTER TABLE archive_items
      ADD CONSTRAINT archive_items_scope_check CHECK (scope IN ('class', 'personal'));
  END IF;
END $$;

-- -----------------------------------------------
-- 3) Indexes for performance
-- -----------------------------------------------
CREATE INDEX IF NOT EXISTS idx_archive_items_scope ON archive_items(scope);
CREATE INDEX IF NOT EXISTS idx_archive_items_owner ON archive_items(owner_id);
CREATE INDEX IF NOT EXISTS idx_archive_items_class ON archive_items(class_id);
CREATE INDEX IF NOT EXISTS idx_archive_items_type_source ON archive_items(source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_archive_items_archived_at ON archive_items(archived_at DESC);

-- -----------------------------------------------
-- 4) Timestamp update trigger
-- -----------------------------------------------
CREATE OR REPLACE FUNCTION update_archive_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_archive_items_updated_at ON archive_items;
CREATE TRIGGER trigger_archive_items_updated_at
BEFORE UPDATE ON archive_items
FOR EACH ROW
EXECUTE FUNCTION update_archive_items_updated_at();

-- -----------------------------------------------
-- 5) Keep backend-driven auth model simple (no restrictive RLS)
-- -----------------------------------------------
ALTER TABLE archive_items DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------
-- 6) Student off-days (replaces localStorage studentOffDays)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS student_off_days (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  day TEXT NOT NULL, -- Mon Tue Wed Thu Fri Sat Sun
  reason TEXT NOT NULL,
  color TEXT DEFAULT '#ffebee',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_off_days_user_id ON student_off_days(user_id);
CREATE INDEX IF NOT EXISTS idx_student_off_days_day ON student_off_days(day);

ALTER TABLE student_off_days DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------
-- 7) Wellness entries (replaces localStorage wellnessJournal)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS wellness_entries (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mood TEXT,
  content TEXT NOT NULL,
  entry_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wellness_entries_user_id ON wellness_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_wellness_entries_entry_date ON wellness_entries(entry_date DESC);

ALTER TABLE wellness_entries DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------
-- 8) Task system safety checks (ensures DB-backed widgets work)
-- -----------------------------------------------
CREATE TABLE IF NOT EXISTS tasks (
  id BIGSERIAL PRIMARY KEY,
  class_id BIGINT REFERENCES classes(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES users(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'personal', -- personal | teacher
  due_date TIMESTAMP WITH TIME ZONE,
  max_score INTEGER,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_student_id ON tasks(student_id);
CREATE INDEX IF NOT EXISTS idx_tasks_teacher_id ON tasks(teacher_id);
CREATE INDEX IF NOT EXISTS idx_tasks_class_id ON tasks(class_id);
CREATE INDEX IF NOT EXISTS idx_tasks_type ON tasks(type);

ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS task_submissions (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_url TEXT,
  file_name TEXT,
  submission_text TEXT,
  score INTEGER,
  feedback TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE,
  graded_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(task_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_task_submissions_task_id ON task_submissions(task_id);
CREATE INDEX IF NOT EXISTS idx_task_submissions_student_id ON task_submissions(student_id);

ALTER TABLE task_submissions DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------
-- 9) Grades system safety checks (student Grades + Analytics)
-- -----------------------------------------------
DO $$
DECLARE
  classes_id_data_type TEXT;
  classes_id_udt_name TEXT;
  grades_class_id_udt_name TEXT;
BEGIN
  SELECT data_type, udt_name
    INTO classes_id_data_type, classes_id_udt_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'classes'
    AND column_name = 'id';

  IF classes_id_udt_name IS NULL THEN
    -- Fallback for unknown/legacy schema; keep migration non-blocking.
    classes_id_data_type := 'bigint';
    classes_id_udt_name := 'int8';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'grades'
  ) THEN
    IF classes_id_data_type = 'uuid' THEN
      EXECUTE '
        CREATE TABLE public.grades (
          id BIGSERIAL PRIMARY KEY,
          user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
          class_id UUID REFERENCES public.classes(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          score DECIMAL(10,2) NOT NULL,
          max_score DECIMAL(10,2) NOT NULL,
          type TEXT NOT NULL DEFAULT ''other'',
          date_taken TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
          notes TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      ';
    ELSE
      EXECUTE '
        CREATE TABLE public.grades (
          id BIGSERIAL PRIMARY KEY,
          user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
          class_id BIGINT REFERENCES public.classes(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          score DECIMAL(10,2) NOT NULL,
          max_score DECIMAL(10,2) NOT NULL,
          type TEXT NOT NULL DEFAULT ''other'',
          date_taken TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
          notes TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      ';
    END IF;
  ELSE
    -- Add missing columns non-destructively
    ALTER TABLE public.grades
      ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
      ADD COLUMN IF NOT EXISTS title TEXT,
      ADD COLUMN IF NOT EXISTS score DECIMAL(10,2),
      ADD COLUMN IF NOT EXISTS max_score DECIMAL(10,2),
      ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'other',
      ADD COLUMN IF NOT EXISTS date_taken TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      ADD COLUMN IF NOT EXISTS notes TEXT,
      ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'grades' AND column_name = 'class_id'
    ) THEN
      IF classes_id_data_type = 'uuid' THEN
        EXECUTE 'ALTER TABLE public.grades ADD COLUMN class_id UUID REFERENCES public.classes(id) ON DELETE CASCADE';
      ELSE
        EXECUTE 'ALTER TABLE public.grades ADD COLUMN class_id BIGINT REFERENCES public.classes(id) ON DELETE CASCADE';
      END IF;
    END IF;

    SELECT udt_name
      INTO grades_class_id_udt_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'grades'
      AND column_name = 'class_id';

    IF grades_class_id_udt_name IS DISTINCT FROM classes_id_udt_name THEN
      RAISE NOTICE 'grades.class_id type (%) differs from classes.id type (%). Consider manual type alignment if grade joins fail.',
        grades_class_id_udt_name, classes_id_udt_name;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_grades_user_id ON grades(user_id);
CREATE INDEX IF NOT EXISTS idx_grades_class_id ON grades(class_id);
CREATE INDEX IF NOT EXISTS idx_grades_date_taken ON grades(date_taken DESC);
CREATE INDEX IF NOT EXISTS idx_grades_type ON grades(type);

CREATE OR REPLACE FUNCTION update_grades_updated_at_safe()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_grades_updated_at_safe ON grades;
CREATE TRIGGER trigger_grades_updated_at_safe
BEFORE UPDATE ON grades
FOR EACH ROW
EXECUTE FUNCTION update_grades_updated_at_safe();

ALTER TABLE grades DISABLE ROW LEVEL SECURITY;

COMMIT;

-- ===============================================
-- Verification
-- ===============================================
SELECT 'archive_items_exists' AS check_name, EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'archive_items'
) AS ok;

SELECT 'archive_items_columns' AS check_name,
       COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'archive_items';

SELECT 'student_off_days_exists' AS check_name, EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'student_off_days'
) AS ok;

SELECT 'wellness_entries_exists' AS check_name, EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'wellness_entries'
) AS ok;

SELECT 'tasks_exists' AS check_name, EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'tasks'
) AS ok;

SELECT 'task_submissions_exists' AS check_name, EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'task_submissions'
) AS ok;

SELECT 'grades_exists' AS check_name, EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'grades'
) AS ok;

SELECT 'grades_column_types' AS check_name,
       json_agg(json_build_object('column', column_name, 'type', data_type) ORDER BY ordinal_position) AS columns
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'grades';
