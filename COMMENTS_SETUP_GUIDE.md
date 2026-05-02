# File Comments System Setup Guide

## Overview
The file comments system allows students and teachers to comment on uploaded files, similar to Google Classroom. This feature enables collaborative discussion around course materials.

## ⚠️ REQUIRED: Database Migration

Before using the comments feature, you **MUST** run the database migration to create the `file_comments` table.

### Steps to Run Migration:

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Navigate to SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the Migration**
   - Open the file: `database-file-comments.sql`
   - Copy the entire contents
   - Paste into the Supabase SQL Editor
   - Click "Run" button

4. **Verify Success**
   - You should see a message: "Success. No rows returned."
   - Go to "Table Editor" → You should now see `file_comments` table

### What the Migration Creates:

```sql
CREATE TABLE file_comments (
  id BIGSERIAL PRIMARY KEY,
  file_id BIGINT REFERENCES class_files(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_file_comments_file_id ON file_comments(file_id);
CREATE INDEX idx_file_comments_user_id ON file_comments(user_id);
CREATE INDEX idx_file_comments_created_at ON file_comments(created_at DESC);
```

## Features

### For Teachers:
- ✅ View all comments on uploaded files
- ✅ Post comments on any file
- ✅ Delete ANY comment (moderator privileges)
- ✅ See student engagement through comments

### For Students:
- ✅ View all comments on class files
- ✅ Post comments on files in enrolled classes
- ✅ Delete their own comments only
- ✅ See teacher responses and classmate discussions

## How to Use

### 1. Upload a File (Teachers Only)
- Go to a class → Files tab
- Click "Upload File"
- Fill in title, description, and select file
- Click "Upload File"

### 2. View File Details
- Click on any file card (preview image or title)
- A modal opens showing:
  - Large file preview (for images) or file icon (for documents)
  - File metadata (title, description, size, upload date)
  - Download and view buttons
  - Comments section below

### 3. Add a Comment
- In the file detail modal
- Type your comment in the text area
- Click "Post" button
- Comment appears instantly with your name, role, and timestamp

### 4. Delete a Comment
- Click "Delete" button on your own comments
- Teachers can delete any comment (including students')
- Confirmation dialog appears before deletion

## User Experience Highlights

### Google Classroom-Style Design
- Clean, card-based layout
- Color-coded file type icons (PDF=red, DOC=blue, XLSX=green)
- Image thumbnails for visual files
- Large preview modal for better visibility

### Smart Timestamps
- "Today" for same-day uploads
- "Yesterday" for previous day
- "X days ago" for recent files
- Full date for older files

### Role Badges
- Comments show user role (TEACHER/STUDENT)
- Color-coded badges for quick identification
- Teacher comments stand out for authority

### Interactive Experience
- Hover effects on cards and buttons
- Smooth modal animations
- Instant comment updates (no page reload)
- Loading states while fetching data

## Authorization Rules

### Comment Posting:
1. User must be logged in
2. AND one of:
   - Student enrolled in the class
   - Teacher who owns the class

### Comment Deletion:
1. User must be logged in
2. AND one of:
   - User is the comment author
   - User is the class teacher (can delete any comment)

## Technical Details

### API Endpoints:
- `GET /api/files/:fileId/comments` - Fetch all comments
- `POST /api/files/:fileId/comments` - Add new comment
- `DELETE /api/files/comments/:commentId` - Delete comment

### Database Schema:
- **file_comments** table with CASCADE delete
- Foreign keys to `class_files` and `users`
- Indexed for fast queries
- Timestamp tracking (created_at, updated_at)

### Frontend Components:
- `FileDetailModal.jsx` - Main modal component
- `FileDetailModal.css` - Google Classroom styling
- Integration in both teacher and student views

## Troubleshooting

### Comments Not Loading
- Check console for errors
- Verify database migration was run successfully
- Ensure user is logged in with valid JWT token
- Check that file_comments table exists in Supabase

### Cannot Post Comments
- Verify you're enrolled in the class (students)
- Check that you're logged in
- Ensure comment_text is not empty
- Check browser console for API errors

### Authorization Errors
- Ensure your role is correctly set in users table
- Verify enrollment in enrollments table (for students)
- Check that classData.teacher_id matches your user.id (for teachers)

## Next Steps

1. ✅ Run database migration (REQUIRED)
2. ✅ Upload a test file as teacher
3. ✅ Click the file card to open detail modal
4. ✅ Post a test comment
5. ✅ Log in as student in another browser
6. ✅ Verify student can see and reply to comments
7. ✅ Test deletion permissions

## Need Help?

- Check browser console (F12) for errors
- Review network tab to see API responses
- Verify Supabase tables and data
- Ensure both backend (port 5000) and frontend (port 3000) are running
