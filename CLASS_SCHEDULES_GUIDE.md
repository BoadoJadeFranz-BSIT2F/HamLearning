# Class Schedules Feature - Implementation Guide

## Overview
Teachers can now add class schedules when creating classes. When students join a class, the schedules automatically appear in their schedule view for the 18-week semester.

## Database Setup

### Step 1: Run the SQL Migration
Open your Supabase dashboard and navigate to the SQL Editor, then run the contents of `MIGRATION-class-schedules.sql`:

```sql
-- This will create:
-- 1. class_schedules table (stores teacher-defined schedules)
-- 2. New columns in schedules table (class_id, is_class_schedule)
-- 3. Indexes for better performance
```

### New Tables/Columns:
- **class_schedules**: Stores the weekly schedule template for each class
  - `id`: Primary key
  - `class_id`: Reference to classes table
  - `day`: Day of week (Mon, Tue, Wed, etc.)
  - `time`: Time (e.g., "9:00 AM", "2:30 PM")
  - `duration_minutes`: Class duration (default 60 minutes)

- **schedules** (updated):
  - `class_id`: Links to the class (if this is a class schedule)
  - `is_class_schedule`: Boolean flag indicating if this was auto-created from class

## Features

### For Teachers:
1. **Create Class with Schedule**
   - Teachers must add at least one schedule when creating a class
   - Can add multiple days/times (e.g., Mon 9:00 AM, Wed 9:00 AM, Fri 9:00 AM)
   - Schedule times are shown as chips that can be removed before creation
   - 18-week semester is the standard duration

2. **Class Code Generation**
   - Unique 6-character code generated automatically
   - Displayed after successful class creation
   - Students use this code to join

### For Students:
1. **Automatic Schedule Addition**
   - When joining a class, schedules automatically appear in "My Schedule"
   - Class schedules are linked to the class (removed if they leave the class)
   - Color-coordinated with other schedules

2. **Schedule View**
   - Shows both personal schedules and class schedules
   - Class schedules are marked with `is_class_schedule: true`
   - Grid view displays all weekly schedules

## API Endpoints

### New/Updated Endpoints:

#### POST `/api/classes/create`
**Body:**
```json
{
  "className": "Introduction to Physics",
  "section": "A",
  "subject": "Physics",
  "room": "Room 101",
  "schedules": [
    { "day": "Mon", "time": "9:00 AM" },
    { "day": "Wed", "time": "9:00 AM" },
    { "day": "Fri", "time": "9:00 AM" }
  ]
}
```

#### POST `/api/classes/join`
**Body:**
```json
{
  "classCode": "ABC123"
}
```
**Response:**
- Creates enrollment
- Copies class schedules to student's schedule table
- Links schedules to class via `class_id`

#### DELETE `/api/classes/:classId/leave`
- Removes enrollment
- Automatically removes all class schedules for that student

#### GET `/api/classes/:classId/schedules`
**Response:**
```json
{
  "schedules": [
    { "id": 1, "day": "Mon", "time": "9:00 AM", "duration_minutes": 60 },
    { "id": 2, "day": "Wed", "time": "9:00 AM", "duration_minutes": 60 }
  ]
}
```

## Frontend Components

### Updated Components:

#### CreateClassModal.jsx
- New state: `schedules` array and `newSchedule` object
- Schedule input section with day/time selectors
- Add/remove schedule functionality
- Validation: Requires at least one schedule
- Display added schedules as removable chips

#### Schedules.jsx (Student View)
- Automatically fetches schedule entries (both personal and class-based)
- Class schedules are marked with `is_class_schedule: true`
- Color-coded display
- Weekly grid view

## Usage Flow

### Teacher Creates Class:
1. Click "Create Class" button
2. Fill in class name, section, subject (optional), room (optional)
3. **Add schedules**: Select day and time, click "Add"
4. Repeat to add multiple schedule times
5. Click "Create" - class code is generated
6. Share code with students

### Student Joins Class:
1. Enter class code in "Join Class" form
2. Click "Join"
3. **Schedules automatically appear** in their Schedule view
4. Class info appears in "My Classes" sidebar

### Student Leaves Class:
1. Navigate to class
2. Click "Leave Class"
3. **Schedules automatically removed** from their Schedule view

## File Structure

```
backend/
  routes/
    classes.js          # Updated: create with schedules, join copies schedules
    schedules.js        # Existing: displays all schedules
  database-class-schedules.sql    # New: table definitions
  migrate-class-schedules.js      # Migration script

frontend/
  src/
    components/
      CreateClassModal.jsx         # Updated: schedule inputs
      CreateClassModal.css         # Updated: schedule styling
      modules/
        Schedules.jsx              # Shows combined schedules

database-class-schedules.sql      # Database migration
MIGRATION-class-schedules.sql     # SQL to run in Supabase
```

## Testing Checklist

- [ ] Run SQL migration in Supabase dashboard
- [ ] Restart backend server
- [ ] Teacher creates class with 2+ schedules
- [ ] Verify class code is generated
- [ ] Student joins class with code
- [ ] Verify schedules appear in student's Schedule view
- [ ] Student leaves class
- [ ] Verify schedules are removed from student's Schedule view
- [ ] Check dashboard widgets update with new class schedules

## Notes

- **18-week semester**: Standard academic semester length
- **Cascading deletes**: When class is deleted, all related schedules are automatically removed
- **Duplicate prevention**: Cannot add same day/time twice to a class
- **Validation**: At least one schedule required for class creation
- **Automatic linking**: Student schedules are linked to class via `class_id` for easy management

## Troubleshooting

### Schedules not appearing for students:
1. Check if class_schedules table exists in Supabase
2. Verify schedules column in join response
3. Check browser console for errors

### Cannot create class:
1. Ensure at least one schedule is added
2. Check backend console for errors
3. Verify database migration ran successfully

### Schedules not removed when leaving:
1. Check class_id foreign key constraint
2. Verify leave endpoint includes schedule deletion
3. Check Supabase logs for errors
