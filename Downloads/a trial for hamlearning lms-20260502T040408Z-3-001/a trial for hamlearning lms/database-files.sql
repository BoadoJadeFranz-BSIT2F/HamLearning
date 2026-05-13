-- Create files/materials table for teacher uploads

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

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_class_files_class_id ON class_files(class_id);
CREATE INDEX IF NOT EXISTS idx_class_files_teacher_id ON class_files(teacher_id);
CREATE INDEX IF NOT EXISTS idx_class_files_upload_date ON class_files(upload_date DESC);

-- Table to track student file views/downloads (optional but useful for analytics)
CREATE TABLE IF NOT EXISTS student_file_access (
    id BIGSERIAL PRIMARY KEY,
    file_id BIGINT NOT NULL REFERENCES class_files(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(file_id, user_id)
);

-- Enable Row Level Security (RLS)
ALTER TABLE class_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_file_access ENABLE ROW LEVEL SECURITY;

-- Policy: Teachers can view and manage their own uploaded files
DROP POLICY IF EXISTS teachers_manage_files ON class_files;
CREATE POLICY teachers_manage_files ON class_files
    FOR ALL
    USING (teacher_id = auth.uid());

-- Policy: Students can view files from classes they're enrolled in
DROP POLICY IF EXISTS students_view_files ON class_files;
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
DROP POLICY IF EXISTS students_track_access ON student_file_access;
CREATE POLICY students_track_access ON student_file_access
    FOR ALL
    USING (user_id = auth.uid());

-- Policy: Teachers can view who accessed their files
DROP POLICY IF EXISTS teachers_view_access ON student_file_access;
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
-- STORAGE BUCKET SETUP
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

-- Storage Policy: Allow authenticated users to upload files to their own folder
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
CREATE POLICY "Allow authenticated uploads" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'class-files');

-- Storage Policy: Allow users to update their files
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
CREATE POLICY "Allow authenticated updates" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'class-files');

-- Storage Policy: Allow users to delete their own files
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
CREATE POLICY "Allow authenticated deletes" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'class-files');

-- Storage Policy: Allow authenticated users to view all files in the bucket
DROP POLICY IF EXISTS "Allow authenticated reads" ON storage.objects;
CREATE POLICY "Allow authenticated reads" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'class-files');
