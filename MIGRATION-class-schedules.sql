-- Complete SQL migration for class schedules feature
-- Run this in your Supabase SQL Editor

-- 1. Create class_schedules table
CREATE TABLE IF NOT EXISTS class_schedules (
  id BIGSERIAL PRIMARY KEY,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  day VARCHAR(10) NOT NULL,
  time VARCHAR(10) NOT NULL,
  duration_minutes INT DEFAULT 60,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(class_id, day, time)
);

-- 2. Add columns to schedules table
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS class_id BIGINT REFERENCES classes(id) ON DELETE CASCADE;
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_class_schedule BOOLEAN DEFAULT false;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_class_schedules_class_id ON class_schedules(class_id);
CREATE INDEX IF NOT EXISTS idx_schedules_class_id ON schedules(class_id);

-- 4. Add comments for documentation
COMMENT ON TABLE class_schedules IS 'Stores the weekly schedule template for each class (18 weeks semester)';
COMMENT ON COLUMN class_schedules.class_id IS 'Reference to the class this schedule belongs to';
COMMENT ON COLUMN class_schedules.day IS 'Day of week: Mon, Tue, Wed, Thu, Fri, Sat, Sun';
COMMENT ON COLUMN class_schedules.time IS 'Time in format like 9:00 AM, 2:30 PM';
COMMENT ON COLUMN class_schedules.duration_minutes IS 'Duration of class session in minutes';
COMMENT ON COLUMN schedules.class_id IS 'Links student schedules to the class they belong to';
COMMENT ON COLUMN schedules.is_class_schedule IS 'True if this schedule entry is from a class enrollment';

-- Verification query
SELECT 
  table_name, 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name IN ('class_schedules', 'schedules')
ORDER BY table_name, ordinal_position;
