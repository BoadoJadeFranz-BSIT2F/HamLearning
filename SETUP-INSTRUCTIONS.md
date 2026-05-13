# Teacher Features Setup Guide

## Issue: "Failed to upload file" error

This happens because the database tables and storage bucket are not yet set up in Supabase.

## Complete Setup Instructions

### Step 1: Create Database Tables

1. Open your **Supabase Dashboard**
2. Go to **SQL Editor** (left sidebar)
3. Click **"New Query"**
4. Copy and paste the **entire content** from `SETUP-TEACHER-FEATURES.sql`
5. Click **"Run"** or press `Ctrl+Enter`
6. ✅ You should see success messages and verification results

---

### Step 2: Create Storage Bucket for Files

1. In Supabase Dashboard, go to **Storage** (left sidebar)
2. Click **"Create a new bucket"**
3. Enter these details:
   - **Name:** `class-files`
   - **Public bucket:** ❌ **UNCHECK** (keep it private)
   - **Allowed MIME types:** Leave empty (or add: `image/*,application/pdf,application/msword,application/vnd.*,text/plain,application/zip`)
4. Click **"Create bucket"**
5. Click on the `class-files` bucket
6. Go to **"Policies"** tab
7. Add these 3 policies:

#### Policy 1: Allow Authenticated Upload
```sql
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'class-files');
```

#### Policy 2: Teachers Delete Own Files
```sql
CREATE POLICY "Teachers can delete their files"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'class-files' AND auth.uid()::text = (storage.foldername(name))[1]);
```

#### Policy 3: Students View Class Files
```sql
CREATE POLICY "Students can view class files"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'class-files');
```

---

### Step 3: Verify Backend Dependencies

Make sure you have installed the `multer` package:

```bash
cd backend
npm install
```

This should already be done since you ran `npm install` earlier.

---

### Step 4: Test the Features

1. **Restart your backend server** (if it's running):
   - Press `Ctrl+C` to stop
   - Run `npm start` or `nodemon server.js` again

2. **Go to your application** at http://localhost:3000

3. **Login as a teacher**

4. **Click on a class card**

5. **Test each tab:**
   - ✅ **Files & Materials** - Upload a file (should work now!)
   - ✅ **Deadlines** - Create a deadline
   - ✅ **Students** - View enrolled students

---

## What Was Fixed

### Database Issues:
- ✅ `class_files` table created with correct data types (BIGINT for class_id)
- ✅ `student_file_access` table created for tracking downloads
- ✅ `deadlines` table recreated with correct data types (was using UUID instead of BIGINT)
- ✅ All Row Level Security policies configured
- ✅ Proper foreign key relationships established

### Storage Issues:
- ✅ Storage bucket `class-files` needs to be created (Step 2 above)
- ✅ Storage policies for upload/delete/view configured

---

## Common Errors and Solutions

### Error: "Failed to upload file"
**Cause:** Storage bucket `class-files` doesn't exist  
**Solution:** Complete Step 2 above

### Error: "relation 'class_files' does not exist"
**Cause:** Database tables not created  
**Solution:** Run `SETUP-TEACHER-FEATURES.sql` (Step 1)

### Error: "Foreign key constraint violation"
**Cause:** Data type mismatch (UUID vs BIGINT)  
**Solution:** The new SQL file fixes this - run it again

### Error: "Permission denied for table class_files"
**Cause:** Row Level Security policies not set  
**Solution:** The SQL file includes all RLS policies - verify they were created

---

## Need Help?

If you still get errors after following these steps:
1. Check the browser console (F12) for error details
2. Check the backend terminal for error messages  
3. Verify you're logged in as a teacher (not a student)
4. Make sure backend server is running on port 5000
5. Make sure frontend is running on port 3000
