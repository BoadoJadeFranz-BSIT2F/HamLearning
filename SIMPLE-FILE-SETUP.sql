-- ===============================================
-- SIMPLE FILE UPLOAD SETUP (Google Classroom-style)
-- No complex RLS on storage - just backend permission checks
-- ===============================================

-- Step 1: Ensure class_files table exists
CREATE TABLE IF NOT EXISTS class_files (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT,
    file_size BIGINT,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Enable RLS on class_files table (not storage!)
ALTER TABLE class_files ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop existing policies
DROP POLICY IF EXISTS "Teachers can insert files" ON class_files;
DROP POLICY IF EXISTS "Anyone enrolled can view files" ON class_files;
DROP POLICY IF EXISTS "Teachers can delete their class files" ON class_files;

-- Step 4: Create simple policies for class_files table
CREATE POLICY "Teachers can insert files" ON class_files
  FOR INSERT 
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "Anyone enrolled can view files" ON class_files
  FOR SELECT 
  USING (
    auth.uid() IN (
      SELECT teacher_id FROM classes WHERE id = class_id
      UNION
      SELECT user_id FROM enrollments WHERE class_id = class_files.class_id
    )
  );

CREATE POLICY "Teachers can delete their class files" ON class_files
  FOR DELETE 
  USING (
    auth.uid() IN (
      SELECT teacher_id FROM classes WHERE id = class_id
    )
  );

-- Step 5: Create storage bucket (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('class-files', 'class-files', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Step 6: Make storage bucket PUBLIC (no RLS needed)
-- Drop all storage policies
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' AND schemaname = 'storage'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
    END LOOP;
END $$;

-- No storage policies needed - bucket is public!

-- Step 7: Verify setup
SELECT 'Tables' as type, tablename 
FROM pg_tables 
WHERE tablename = 'class_files';

SELECT 'Bucket' as type, name, public 
FROM storage.buckets 
WHERE name = 'class-files';

SELECT 'Storage Policies' as type, COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

SELECT 'Table Policies' as type, policyname
FROM pg_policies 
WHERE tablename = 'class_files';
