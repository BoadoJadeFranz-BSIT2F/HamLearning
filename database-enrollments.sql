-- Drop and create enrollments table
DROP TABLE IF EXISTS enrollments CASCADE;

CREATE TABLE enrollments (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add unique constraint to prevent duplicate enrollments
ALTER TABLE enrollments ADD CONSTRAINT unique_user_class UNIQUE (user_id, class_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_enrollments_user_id ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_class_id ON enrollments(class_id);

-- Disable RLS for simplicity
ALTER TABLE enrollments DISABLE ROW LEVEL SECURITY;
