-- ===============================================
-- FILE UPLOAD VERIFICATION SCRIPT
-- Run this in Supabase SQL Editor to check setup
-- ===============================================

-- 1. Check if class_files table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'class_files'
) as class_files_exists;

-- 2. Check if student_file_access table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'student_file_access'
) as student_file_access_exists;

-- 3. Check storage bucket exists
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id = 'class-files';

-- 4. List all RLS policies on class_files
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'class_files';

-- 5. List all storage policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 6. Check class_files table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'class_files'
ORDER BY ordinal_position;

-- 7. Test if you can insert (will fail if table doesn't exist)
-- Comment out after verification
-- SELECT COUNT(*) as file_count FROM class_files;
