-- ===============================================
-- DIAGNOSTIC CHECK - RUN THIS TO FIND THE PROBLEM
-- ===============================================

-- 1. Check if class_files table exists and its structure
SELECT 
    'class_files table' as check_name,
    CASE 
        WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'class_files')
        THEN 'EXISTS ✓'
        ELSE 'MISSING ✗'
    END as status;

-- 2. Check if storage bucket exists
SELECT 
    'class-files bucket' as check_name,
    CASE 
        WHEN EXISTS (SELECT FROM storage.buckets WHERE id = 'class-files')
        THEN 'EXISTS ✓'
        ELSE 'MISSING ✗'
    END as status;

-- 3. Check table RLS policies count
SELECT 
    'Table RLS policies' as check_name,
    COUNT(*)::text || ' policies' as status
FROM pg_policies 
WHERE tablename = 'class_files';

-- 4. Check storage RLS policies count
SELECT 
    'Storage RLS policies' as check_name,
    COUNT(*)::text || ' policies' as status
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- 5. Check if RLS is enabled on class_files
SELECT 
    'RLS enabled on class_files' as check_name,
    CASE 
        WHEN relrowsecurity THEN 'ENABLED ✓'
        ELSE 'DISABLED ✗'
    END as status
FROM pg_class 
WHERE relname = 'class_files';

-- 6. List all storage policies
SELECT 
    'Storage policy: ' || policyname as check_name,
    cmd::text as status
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- 7. Check if you can query class_files table (tests RLS)
SELECT 
    'Can SELECT from class_files' as check_name,
    'YES ✓' as status
FROM class_files
LIMIT 0;

-- 8. Verify bucket configuration
SELECT 
    'Bucket: ' || id as check_name,
    'Public: ' || public::text || ', Size limit: ' || (file_size_limit/1024/1024)::text || 'MB' as status
FROM storage.buckets 
WHERE id = 'class-files';
