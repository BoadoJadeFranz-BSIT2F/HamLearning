-- ===============================================
-- COMPLETE STORAGE FIX - Make storage work without RLS
-- Run this in Supabase SQL Editor
-- ===============================================

-- Step 1: Drop ALL storage policies (clean slate)
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

-- Step 2: Create ONE simple policy that allows EVERYTHING
CREATE POLICY "allow_all" ON storage.objects
  FOR ALL 
  USING (true)
  WITH CHECK (true);

-- Step 3: Make bucket public
UPDATE storage.buckets 
SET public = true 
WHERE name = 'class-files';

-- Step 4: Ensure class_files table has correct policies
DROP POLICY IF EXISTS "Teachers can insert files" ON class_files;
DROP POLICY IF EXISTS "Anyone enrolled can view files" ON class_files;
DROP POLICY IF EXISTS "Teachers can delete their class files" ON class_files;

-- Disable RLS on class_files temporarily to test
ALTER TABLE class_files DISABLE ROW LEVEL SECURITY;

-- Step 5: Verify
SELECT 'Storage Policies Count' as check_type, COUNT(*) as result
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

SELECT 'Storage Policy Details' as check_type, policyname, cmd
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

SELECT 'Bucket Public Status' as check_type, name, public as result
FROM storage.buckets 
WHERE name = 'class-files';

SELECT 'class_files RLS' as check_type, 
       CASE WHEN relrowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as result
FROM pg_class 
WHERE relname = 'class_files';
