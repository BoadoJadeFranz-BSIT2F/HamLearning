-- ===============================================
-- COMPLETE SETUP FOR TEACHER FEATURES
-- Run this entire file in Supabase SQL Editor
-- ===============================================

-- ===============================================
-- 1. FILES & MATERIALS TABLES
-- ===============================================

-- Drop existing tables if they have type mismatches
DROP TABLE IF EXISTS student_file_access CASCADE;
DROP TABLE IF EXISTS class_files CASCADE;

-- Table to store uploaded files/materials
CREATE TABLE IF NOT EXISTS class_files (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50) NOT NULL, -- pdf, doc, docx, ppt, pptx, etc.
    file_size BIGINT, -- in bytes
    title VARCHAR(255) NOT NULL,
    description TEXT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table to track student file views/downloads
CREATE TABLE IF NOT EXISTS student_file_access (
    id BIGSERIAL PRIMARY KEY,
    file_id BIGINT NOT NULL REFERENCES class_files(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(file_id, user_id)
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_class_files_class_id ON class_files(class_id);
CREATE INDEX IF NOT EXISTS idx_class_files_teacher_id ON class_files(teacher_id);
CREATE INDEX IF NOT EXISTS idx_class_files_upload_date ON class_files(upload_date DESC);
CREATE INDEX IF NOT EXISTS idx_student_file_access_file_id ON student_file_access(file_id);
CREATE INDEX IF NOT EXISTS idx_student_file_access_user_id ON student_file_access(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE class_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_file_access ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS teachers_manage_files ON class_files;
DROP POLICY IF EXISTS students_view_files ON class_files;
DROP POLICY IF EXISTS students_track_access ON student_file_access;
DROP POLICY IF EXISTS teachers_view_access ON student_file_access;

-- Policy: Teachers can view and manage their own uploaded files
CREATE POLICY teachers_manage_files ON class_files
    FOR ALL
    USING (teacher_id = auth.uid());

-- Policy: Students can view files from classes they're enrolled in
CREATE POLICY students_view_files ON class_files
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM enrollments
            WHERE enrollments.class_id = class_files.class_id
            AND enrollments.user_id = auth.uid()
        )
    );

-- Policy: Students can track their file access
CREATE POLICY students_track_access ON student_file_access
    FOR ALL
    USING (user_id = auth.uid());

-- Policy: Teachers can view who accessed their files
CREATE POLICY teachers_view_access ON student_file_access
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_files
            WHERE class_files.id = student_file_access.file_id
            AND class_files.teacher_id = auth.uid()
        )
    );

-- ===============================================
-- 2. DEADLINES TABLE (FIXED DATA TYPES)
-- ===============================================

-- Drop and recreate deadlines table with correct data types
DROP TABLE IF EXISTS deadlines CASCADE;

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

-- Enable RLS
ALTER TABLE deadlines ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS teachers_manage_deadlines ON deadlines;
DROP POLICY IF EXISTS students_view_deadlines ON deadlines;

-- Policy: Teachers can manage their own deadlines
CREATE POLICY teachers_manage_deadlines ON deadlines
    FOR ALL
    USING (teacher_id = auth.uid());

-- Policy: Students can view deadlines from their enrolled classes
CREATE POLICY students_view_deadlines ON deadlines
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM enrollments
            WHERE enrollments.class_id = deadlines.class_id
            AND enrollments.user_id = auth.uid()
        )
    );

-- Create trigger to update updated_at timestamp
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

-- ===============================================
-- 3. STORAGE BUCKET SETUP
-- ===============================================

-- Create storage bucket for file uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'class-files',
  'class-files',
  false,
  52428800, -- 50MB limit
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg',
    'image/png',
    'image/gif',
    'text/plain',
    'application/zip',
    'application/x-zip-compressed'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Authenticated users can upload files" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can delete their files" ON storage.objects;
DROP POLICY IF EXISTS "Students can view class files" ON storage.objects;

-- Storage Policy 1: Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'class-files');

-- Storage Policy 2: Teachers can delete their own files
CREATE POLICY "Teachers can delete their files"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'class-files' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage Policy 3: Authenticated users can view class files
CREATE POLICY "Students can view class files"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'class-files');

-- ===============================================
-- 4. VERIFICATION QUERIES
-- ===============================================

-- Check if tables were created successfully
SELECT 'class_files table' AS table_name, COUNT(*) AS record_count FROM class_files
UNION ALL
SELECT 'student_file_access table' AS table_name, COUNT(*) AS record_count FROM student_file_access
UNION ALL
SELECT 'deadlines table' AS table_name, COUNT(*) AS record_count FROM deadlines;

-- Check if storage bucket was created
SELECT 
  id,
  name,
  public,
  file_size_limit,
  created_at
FROM storage.buckets
WHERE id = 'class-files';

-- Display table structures
SELECT 
    'class_files' AS table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'class_files'
ORDER BY ordinal_position;

-- ===============================================
-- SETUP COMPLETE! 
-- ===============================================
-- If you see results above with no errors, you're all set!
-- 
-- Next steps:
-- 1. Restart your backend server (Ctrl+C, then npm start)
-- 2. Go to http://localhost:3000
-- 3. Login as a teacher
-- 4. Click a class card
-- 5. Test Files, Deadlines, and Students tabs
-- ===============================================
