-- ===============================================
-- USERS TABLE SETUP FOR HAMLEARNING LMS
-- Run this in Supabase SQL Editor
-- ===============================================

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'student', -- 'student' or 'teacher'
  major TEXT,
  academic_year TEXT,
  target_gpa DECIMAL(3, 2),
  department TEXT,
  subjects TEXT,
  profile_picture TEXT,
  profile_completed BOOLEAN DEFAULT false,
  auth_provider TEXT DEFAULT 'email',
  reset_token TEXT,
  reset_token_expires TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Disable RLS to allow backend API access
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Grant permissions to anon role (for unauthenticated API access)
GRANT ALL ON users TO anon;
GRANT ALL ON users TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- ===============================================
-- VERIFY SETUP
-- ===============================================

-- Check if users table exists and has correct schema
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'users';
