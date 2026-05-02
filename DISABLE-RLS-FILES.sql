-- ===============================================
-- DISABLE RLS ON CLASS_FILES TABLE
-- Since we're using local file storage, no need for complex RLS
-- ===============================================

-- Disable RLS on class_files table
ALTER TABLE class_files DISABLE ROW LEVEL SECURITY;

-- Verify
SELECT 'class_files RLS Status' as check_type, 
       CASE WHEN relrowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as status
FROM pg_class 
WHERE relname = 'class_files';
