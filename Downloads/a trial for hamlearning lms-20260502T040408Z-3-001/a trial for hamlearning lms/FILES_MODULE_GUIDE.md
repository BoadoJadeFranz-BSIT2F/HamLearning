# Files & Materials Setup Guide

This guide will help you set up the Files & Materials feature in your LMS.

## Database Setup

1. **Run the SQL schema** in your Supabase SQL Editor:
   - Open the `database-files.sql` file
   - Copy the entire contents
   - Paste and run it in Supabase SQL Editor

2. **Create Storage Bucket** in Supabase:
   - Go to Storage in your Supabase dashboard
   - Create a new bucket named `class-files`
   - Set it to **Private** (not public)
   - The policies in the SQL file will handle access control

3. **Install Backend Dependencies**:
   ```bash
   cd backend
   npm install
   ```
   This will install the `multer` package needed for file uploads.

## Features

### For Teachers:
- Upload files (PDF, DOC, DOCX, PPT, PPTX, XLS, XLSX, images, ZIP)
- Maximum file size: 50MB
- Files are organized by class
- Each file can have:
  - Title (required)
  - Description (optional)
  - Associated class
- Teachers can delete their own files

### For Students:
- View all files from enrolled classes
- Download files
- See file details:
  - File name and type
  - File size
  - Upload date
  - Teacher who uploaded it
  - Class it belongs to

## File Types Supported

- **Documents**: PDF, DOC, DOCX
- **Presentations**: PPT, PPTX
- **Spreadsheets**: XLS, XLSX
- **Images**: JPG, JPEG, PNG, GIF
- **Text**: TXT
- **Archives**: ZIP

## Usage

### Teacher Workflow:
1. Go to Dashboard → Files & Materials
2. Click "Upload File"
3. Select the class
4. Enter a title and optional description
5. Choose the file
6. Click "Upload File"
7. The file will be available to all students enrolled in that class

### Student Workflow:
1. Go to Tasks module
2. Click on "Files & Materials" tab
3. View all available files from your classes
4. Click "Download" to access any file
5. File access is automatically tracked

## API Endpoints

### Teacher Endpoints:
- `POST /api/files/upload` - Upload a file
- `GET /api/files/my-uploads` - Get all uploaded files
- `GET /api/files/class/:classId` - Get files for a specific class
- `DELETE /api/files/:fileId` - Delete a file

### Student Endpoints:
- `GET /api/files/my-files` - Get all files from enrolled classes
- `POST /api/files/track-access/:fileId` - Track file download/view

## Security Features

- Row Level Security (RLS) enabled on database tables
- Teachers can only manage their own files
- Students can only view files from classes they're enrolled in
- Files are stored privately in Supabase Storage
- File type validation on upload
- File size limits enforced

## Troubleshooting

### File Upload Fails:
- Check that the `class-files` bucket exists in Supabase Storage
- Verify the bucket is set to private
- Ensure the file size is under 50MB
- Check that the file type is allowed

### Students Can't See Files:
- Verify the student is enrolled in the class with 'approved' status
- Check that the file's `is_active` flag is true
- Ensure RLS policies are properly set up

### Storage Errors:
- Verify Supabase storage quotas aren't exceeded
- Check Firebase/Supabase API keys in .env file
- Ensure storage policies are properly configured

## Notes

- Files are soft-deleted (marked as inactive) rather than permanently removed
- File access tracking helps teachers see which students have viewed materials
- All file operations are logged in the backend console for debugging
