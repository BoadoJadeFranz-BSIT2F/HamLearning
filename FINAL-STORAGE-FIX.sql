-- ===============================================
-- STORAGE POLICY FIX - RUN THIS IN SUPABASE
-- This will delete old policies and create one simple policy
-- ===============================================

-- Step 1: Delete ALL existing storage policies
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated reads" ON storage.objects;
DROP POLICY IF EXISTS "upload_files" ON storage.objects;
DROP POLICY IF EXISTS "update_files" ON storage.objects;
DROP POLICY IF EXISTS "delete_files" ON storage.objects;
DROP POLICY IF EXISTS "read_files" ON storage.objects;

-- Also delete any other policies that might exist
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' AND schemaname = 'storage' AND NOT policyname = 'allow_all_authenticated'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
    END LOOP;
END $$;

-- Step 2: Create ONE simple policy that allows everything for authenticated users
DROP POLICY IF EXISTS "allow_all_authenticated" ON storage.objects;

CREATE POLICY "allow_all_authenticated" ON storage.objects
  FOR ALL 
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Step 3: Verify - should show exactly 1 policy
SELECT 'Final result' as status, COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Step 4: Show the policy details
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';
