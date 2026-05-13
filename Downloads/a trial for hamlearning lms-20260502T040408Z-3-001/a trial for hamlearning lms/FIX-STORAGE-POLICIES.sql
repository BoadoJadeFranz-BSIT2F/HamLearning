-- ===============================================
-- FIX STORAGE POLICIES - DELETE ALL AND RECREATE
-- Run this to fix conflicting storage policies
-- ===============================================

-- Step 1: List all current storage policies to see what exists
SELECT policyname FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Step 2: Delete ALL existing storage policies (clean slate)
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

-- Step 3: Verify all policies deleted
SELECT COUNT(*) as remaining_policies FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Step 4: Create ONLY 4 simple policies
CREATE POLICY "upload_files" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'class-files');

CREATE POLICY "update_files" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'class-files');

CREATE POLICY "delete_files" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'class-files');

CREATE POLICY "read_files" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'class-files');

-- Step 5: Verify exactly 4 policies created
SELECT 'Final check' as status, COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Step 6: List the new policies
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;
