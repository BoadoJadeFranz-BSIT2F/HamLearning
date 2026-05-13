-- Create class_schedules table to store schedule templates for each class
CREATE TABLE IF NOT EXISTS class_schedules (
  id BIGSERIAL PRIMARY KEY,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  day VARCHAR(10) NOT NULL, -- Mon, Tue, Wed, Thu, Fri, Sat, Sun
  time VARCHAR(10) NOT NULL, -- 9:00 AM, 10:00 AM, etc.
  duration_minutes INT DEFAULT 60,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(class_id, day, time)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_class_schedules_class_id ON class_schedules(class_id);

-- Add class_id reference to schedules table for linking
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS class_id BIGINT REFERENCES classes(id) ON DELETE CASCADE;
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_class_schedule BOOLEAN DEFAULT false;

-- Create index for class schedules
CREATE INDEX IF NOT EXISTS idx_schedules_class_id ON schedules(class_id);

COMMENT ON TABLE class_schedules IS 'Stores the weekly schedule template for each class that teachers create';
COMMENT ON COLUMN schedules.class_id IS 'Links student schedules to the class they belong to';
COMMENT ON COLUMN schedules.is_class_schedule IS 'Indicates if this schedule entry is from a class enrollment';
