-- Create file_comments table for student and teacher comments on class files
CREATE TABLE IF NOT EXISTS file_comments (
    id BIGSERIAL PRIMARY KEY,
    file_id BIGINT NOT NULL REFERENCES class_files(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_file_comments_file_id ON file_comments(file_id);
CREATE INDEX IF NOT EXISTS idx_file_comments_user_id ON file_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_file_comments_created_at ON file_comments(created_at DESC);

-- Disable RLS for simplicity (or configure appropriate policies)
ALTER TABLE file_comments DISABLE ROW LEVEL SECURITY;
