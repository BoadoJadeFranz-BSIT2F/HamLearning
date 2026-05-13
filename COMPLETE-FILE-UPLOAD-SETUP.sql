-- ===============================================
-- COMPLETE FILE UPLOAD SETUP - RUN THIS ENTIRE FILE
-- This will create everything needed for file uploads
-- ===============================================

-- Step 1: Create class_files table
CREATE TABLE IF NOT EXISTS class_files (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 2: Create indexes
CREATE INDEX IF NOT EXISTS idx_class_files_class_id ON class_files(class_id);
CREATE INDEX IF NOT EXISTS idx_class_files_teacher_id ON class_files(teacher_id);
CREATE INDEX IF NOT EXISTS idx_class_files_upload_date ON class_files(upload_date DESC);

-- Step 3: Create student_file_access table
CREATE TABLE IF NOT EXISTS student_file_access (
    id BIGSERIAL PRIMARY KEY,
    file_id BIGINT NOT NULL REFERENCES class_files(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(file_id, user_id)
);

-- Step 4: Enable RLS
ALTER TABLE class_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_file_access ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS teachers_manage_files ON class_files;
DROP POLICY IF EXISTS students_view_files ON class_files;
DROP POLICY IF EXISTS students_track_access ON student_file_access;
DROP POLICY IF EXISTS teachers_view_access ON student_file_access;

-- Step 6: Create RLS policies for tables
CREATE POLICY teachers_manage_files ON class_files
    FOR ALL TO authenticated
    USING (teacher_id = auth.uid());

CREATE POLICY students_view_files ON class_files
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM enrollments
            WHERE enrollments.class_id = class_files.class_id
            AND enrollments.user_id = auth.uid()
        )
    );

CREATE POLICY students_track_access ON student_file_access
    FOR ALL TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY teachers_view_access ON student_file_access
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM class_files
            WHERE class_files.id = student_file_access.file_id
            AND class_files.teacher_id = auth.uid()
        )
    );

-- Step 7: Create storage bucket (will skip if exists)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'class-files',
  'class-files',
  false,
  52428800,
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

-- Step 8: Drop existing storage policies
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated reads" ON storage.objects;

-- Step 9: Create storage policies
CREATE POLICY "Allow authenticated uploads" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'class-files');

CREATE POLICY "Allow authenticated updates" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'class-files');

CREATE POLICY "Allow authenticated deletes" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'class-files');

CREATE POLICY "Allow authenticated reads" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'class-files');

-- Step 10: Verify setup
SELECT 'Tables created' as status, 
       EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'class_files') as class_files_exists,
       EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'student_file_access') as student_file_access_exists;

SELECT 'Storage bucket' as status, COUNT(*) as bucket_count 
FROM storage.buckets WHERE id = 'class-files';

SELECT 'Table policies' as status, COUNT(*) as policy_count 
FROM pg_policies WHERE tablename = 'class_files';

SELECT 'Storage policies' as status, COUNT(*) as policy_count 
FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
