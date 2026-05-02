# Deadlines Module Guide

## Overview
The Deadlines Module allows teachers to create, manage, and mark deadlines as complete, while students can view all their deadlines from enrolled classes.

## Features

### For Teachers:
- ✅ Create deadlines with title, description, type, and due date/time
- ✅ Edit existing deadlines
- ✅ Delete deadlines
- ✅ Mark deadlines as complete/incomplete on the due date/time
- ✅ View all deadlines for their classes
- ✅ See overdue deadlines highlighted
- ✅ Filter by assignment, project, exam, quiz, or other

### For Students:
- ✅ View all deadlines from enrolled classes
- ✅ See upcoming deadlines (within 7 days)
- ✅ View overdue deadlines
- ✅ Track completed deadlines
- ✅ Statistics dashboard showing total, upcoming, overdue, and completed deadlines
- ✅ Filter deadlines by status
- ✅ Real-time countdown showing time until deadline

## Setup Instructions

### 1. Database Setup
Run the SQL script in Supabase SQL Editor:

```bash
database-deadlines.sql
```

This creates:
- `deadlines` table with all necessary columns
- Indexes for performance optimization
- Auto-update trigger for `updated_at` timestamp

### 2. Backend Setup
The backend is already configured with:
- `/api/deadlines` routes in `backend/routes/deadlines.js`
- Server integration in `backend/server.js`
- API endpoints in `frontend/src/services/api.js`

### 3. Frontend Components
Two main components have been created:
- **TeacherDeadlines**: `frontend/src/components/teacher-modules/TeacherDeadlines.jsx`
- **Deadlines (Student)**: `frontend/src/components/modules/Deadlines.jsx`

## How to Use

### For Teachers:

#### Creating a Deadline:
1. Navigate to a class in the Teacher Dashboard
2. Click on the "Deadlines" tab
3. Click the "+ Add Deadline" button
4. Fill in the form:
   - **Title**: Name of the assignment/task (required)
   - **Description**: Additional details (optional)
   - **Type**: Choose from Assignment, Project, Exam, Quiz, or Other (required)
   - **Due Date**: Select the date (required)
   - **Due Time**: Select the time (required)
5. Click "Create Deadline"

#### Editing a Deadline:
1. Click the pencil (✏️) icon on any deadline card
2. Update the information
3. Click "Update Deadline"

#### Deleting a Deadline:
1. Click the trash (🗑️) icon on any deadline card
2. Confirm the deletion

#### Marking as Complete:
1. When the deadline date/time arrives, click "✓ Mark Complete" button
2. The deadline will be marked as done and moved to completed section
3. Click "↩️ Mark Incomplete" to undo if needed

### For Students:

#### Viewing Deadlines:
1. Navigate to Dashboard
2. Click on "Deadlines" in the sidebar
3. View all deadlines from enrolled classes

#### Using Filters:
- **All**: Shows all deadlines
- **Due This Week**: Shows upcoming deadlines within 7 days
- **Overdue**: Shows past deadlines that aren't completed
- **Completed**: Shows completed deadlines

#### Understanding the Display:
- **Stats Cards**: Quick overview of total, upcoming, overdue, and completed deadlines
- **Color Coding**: 
  - Blue border: Assignment
  - Purple border: Project
  - Red border: Exam
  - Orange border: Quiz
  - Gray border: Other
- **Time Remaining**: Shows countdown like "3 days left" or "5 hours left"
- **Overdue Badge**: Red warning for past deadlines

## API Endpoints

### Get Class Deadlines
```
GET /api/deadlines/class/:classId
```
Returns all deadlines for a specific class.

### Get Student's All Deadlines
```
GET /api/deadlines/my-deadlines
```
Returns all deadlines from all enrolled classes.

### Create Deadline (Teachers Only)
```
POST /api/deadlines
Body: {
  classId: string,
  title: string,
  description: string (optional),
  type: string,
  dueDate: ISO date string
}
```

### Update Deadline (Teachers Only)
```
PUT /api/deadlines/:id
Body: {
  title: string (optional),
  description: string (optional),
  type: string (optional),
  dueDate: ISO date string (optional),
  isCompleted: boolean (optional)
}
```

### Delete Deadline (Teachers Only)
```
DELETE /api/deadlines/:id
```

### Mark Complete/Incomplete (Teachers Only)
```
PATCH /api/deadlines/:id/complete
Body: {
  isCompleted: boolean
}
```

## Database Schema

```sql
deadlines (
  id UUID PRIMARY KEY,
  class_id UUID REFERENCES classes(id),
  teacher_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
```

## Deadline Types

1. **Assignment**: Regular homework or assignments
2. **Project**: Larger projects or group work
3. **Exam**: Midterms, finals, or other exams
4. **Quiz**: Short quizzes or tests
5. **Other**: Any other type of deadline

## Color Scheme

- **Assignment**: Blue (#3b82f6)
- **Project**: Purple (#8b5cf6)
- **Exam**: Red (#ef4444)
- **Quiz**: Orange (#f59e0b)
- **Other**: Gray (#6b7280)

## Tips

### For Teachers:
- Set deadlines well in advance to give students time to prepare
- Use clear, descriptive titles
- Add descriptions with submission instructions or requirements
- Mark deadlines as complete when the due date passes
- Review overdue items regularly

### For Students:
- Check the Deadlines module daily
- Focus on "Due This Week" filter for urgent items
- Use the countdown feature to plan your time
- Complete work before deadlines to avoid overdue status

## Troubleshooting

### Deadlines not showing up?
1. Ensure the database table was created (run `database-deadlines.sql`)
2. Check that you're enrolled in classes (for students)
3. Verify the backend server is running
4. Check browser console for errors

### Can't create deadlines?
1. Verify you're logged in as a teacher
2. Ensure you're viewing your own class
3. Check that all required fields are filled
4. Make sure the due date/time is valid

### Backend errors?
1. Restart the backend server: `cd backend && npm start`
2. Check Supabase connection in `backend/config/supabase.js`
3. Verify JWT token is valid

## Future Enhancements

Potential features to add:
- Email/push notifications for upcoming deadlines
- Student submission tracking
- Deadline templates for recurring assignments
- Calendar view integration
- Export deadlines to calendar apps (iCal, Google Calendar)
- Student comments or questions on deadlines
- Attachment support for assignment files
- Grading integration

## Support

For issues or questions, please refer to the main README.md or contact your system administrator.
