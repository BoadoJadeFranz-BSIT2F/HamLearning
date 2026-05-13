# 🎓 Google Classroom-Style Implementation Guide

## 📋 Step-by-Step Implementation

### **STEP 1: Database Setup** ✅
**File:** `database-complete-classroom-system.sql`

Run this entire file in Supabase SQL Editor. It creates:
- ✅ `enrollments` - Student-class relationships
- ✅ `deadlines` - Assignments/tasks with file uploads
- ✅ `deadline_files` - Files attached by teacher to deadline
- ✅ `submissions` - Student work submissions (auto-created when deadline posted)
- ✅ `submission_files` - Files uploaded by students
- ✅ `class_files` - Reference materials only (no submission required)
- ✅ Auto-triggers for late detection and submission creation

---

### **STEP 2: Backend API Routes**

#### **A. Deadlines Routes** (`/api/deadlines`)
```
POST   /deadlines/create        - Create deadline with file upload
GET    /deadlines/class/:id     - Get all deadlines for a class
GET    /deadlines/:id          - Get single deadline with files
GET    /deadlines/:id/submissions - Get all student submissions for deadline
PUT    /deadlines/:id          - Update deadline
DELETE /deadlines/:id          - Delete deadline
POST   /deadlines/:id/files     - Add files to existing deadline
```

#### **B. Submissions Routes** (`/api/submissions`)
```
GET    /submissions/student/:deadlineId - Get student's submission for a deadline
POST   /submissions/submit              - Submit work (creates/updates submission)
POST   /submissions/:id/files           - Upload files to submission
PUT    /submissions/:id/grade           - Teacher grades submission
GET    /submissions/student/all         - Get all submissions for current student
```

---

### **STEP 3: Frontend - Teacher Dashboard**

#### **A. TeacherDeadlines Component** (MAIN CHANGES)
**Location:** `frontend/src/components/teacher-modules/TeacherDeadlines.jsx`

**Changes Required:**
1. ✅ Add file upload to "Create Deadline" form (multipart/form-data)
2. ✅ Show deadline list like Google Classroom feed
3. ✅ Click deadline → open DeadlineDetailModal

**Form Structure:**
```jsx
<form onSubmit={handleSubmit}>
  <input name="title" placeholder="Assignment Title" required />
  <textarea name="instructions" placeholder="Instructions" />
  <select name="type">
    <option value="assignment">Assignment</option>
    <option value="project">Project</option>
    <option value="quiz">Quiz</option>
  </select>
  <input type="date" name="dueDate" required />
  <input type="time" name="dueTime" required />
  <input type="number" name="points" placeholder="Points (100)" />
  
  {/* FILE UPLOAD SECTION - MOVED FROM FILES & MATERIALS */}
  <div className="file-upload-section">
    <label>Attach Materials (optional)</label>
    <input 
      type="file" 
      multiple 
      onChange={handleFileSelect}
      accept=".pdf,.doc,.docx,.ppt,.pptx,.jpg,.png"
    />
    <div className="selected-files-preview">
      {/* Show selected files before upload */}
    </div>
  </div>
  
  <button type="submit">Create Assignment</button>
</form>
```

#### **B. DeadlineDetailModal Component** (NEW)
**Location:** `frontend/src/components/teacher-modules/DeadlineDetailModal.jsx`

**Features:**
- Shows deadline title, instructions, attached files
- Lists ALL students enrolled in class (alphabetically)
- Each student shows:
  * ✅ Submitted / ❌ Not Submitted / ⏰ Late
  * Submission time
  * Grade (if graded)
- Click student → opens StudentSubmissionView

**Structure:**
```jsx
<div className="deadline-detail-modal">
  <div className="deadline-header">
    <h2>{deadline.title}</h2>
    <p>{deadline.instructions}</p>
    <div className="deadline-files">
      {/* Teacher's attached materials */}
    </div>
  </div>
  
  <div className="submissions-list">
    <h3>Student Submissions ({submittedCount}/{totalStudents})</h3>
    {students.sort((a,b) => a.name.localeCompare(b.name)).map(student => (
      <div className="student-submission-card" onClick={() => viewSubmission(student)}>
        <div className="student-info">
          <span className="student-name">{student.name}</span>
          <span className="student-status">
            {student.status === 'turned_in' ? '✅ Submitted' : '❌ Not Submitted'}
            {student.is_late && ' ⏰ Late'}
          </span>
        </div>
        {student.submitted_at && (
          <div className="submission-time">
            Submitted: {formatDate(student.submitted_at)}
          </div>
        )}
        {student.grade && (
          <div className="grade-display">
            Grade: {student.grade}/{deadline.points}
          </div>
        )}
      </div>
    ))}
  </div>
</div>
```

#### **C. StudentSubmissionView Component** (NEW)
**Location:** `frontend/src/components/teacher-modules/StudentSubmissionView.jsx`

**Features:**
- Shows student's uploaded files
- Shows submission time
- Input field for grade
- Feedback text area

---

### **STEP 4: Frontend - Student Dashboard**

#### **A. StudentDeadlines Component** (NEW)
**Location:** `frontend/src/components/modules/StudentDeadlines.jsx`

**Features:**
- Shows deadlines from ALL enrolled classes
- Groups by: To Do / Completed / Missing
- Click deadline → opens StudentDeadlineView

**Structure:**
```jsx
<div className="student-deadlines">
  <div className="deadline-filters">
    <button onClick={() => setFilter('todo')}>To Do</button>
    <button onClick={() => setFilter('completed')}>Completed</button>
    <button onClick={() => setFilter('missing')}>Missing</button>
  </div>
  
  <div className="deadlines-list">
    {filteredDeadlines.map(deadline => (
      <div className="deadline-card" onClick={() => openDeadline(deadline)}>
        <div className="deadline-header">
          <h3>{deadline.title}</h3>
          <span className="class-name">{deadline.className}</span>
        </div>
        <div className="deadline-status">
          {getStatusBadge(deadline.submission)}
        </div>
        <div className="deadline-due">
          Due: {formatDueDate(deadline.due_date)}
        </div>
      </div>
    ))}
  </div>
</div>
```

#### **B. StudentDeadlineView Component** (NEW)
**Location:** `frontend/src/components/modules/StudentDeadlineView.jsx`

**Features:**
- Shows teacher's instructions and attached files
- File upload for submission
- Text/link submission option
- "Turn In" button
- Shows previous submission if exists

**Structure:**
```jsx
<div className="student-deadline-view">
  <div className="assignment-details">
    <h2>{deadline.title}</h2>
    <div className="assignment-meta">
      <span>Due: {formatDueDate(deadline.due_date)}</span>
      <span>Points: {deadline.points}</span>
    </div>
    <p>{deadline.instructions}</p>
    
    {/* Teacher's materials */}
    <div className="teacher-materials">
      <h4>Materials</h4>
      {deadline.files.map(file => (
        <a href={file.url} download>{file.name}</a>
      ))}
    </div>
  </div>
  
  <div className="your-work">
    <h3>Your Work</h3>
    
    {submission?.status === 'turned_in' ? (
      // Show submitted work
      <div className="submitted-work">
        <p>✅ Turned in {formatDate(submission.submitted_at)}</p>
        {submission.files.map(file => (
          <div>{file.name}</div>
        ))}
        {submission.grade && <p>Grade: {submission.grade}/{deadline.points}</p>}
        <button onClick={unsubmit}>Unsubmit</button>
      </div>
    ) : (
      // Submission form
      <div className="submission-form">
        <input 
          type="file" 
          multiple 
          onChange={handleFileSelect}
        />
        <textarea 
          placeholder="Add a comment..." 
          value={comment}
          onChange={(e) => setComment(e.target.value)}
        />
        <button onClick={handleTurnIn} disabled={!hasWork}>
          Turn In
        </button>
      </div>
    )}
  </div>
</div>
```

---

### **STEP 5: Remove File Upload from Files & Materials**

**File:** `frontend/src/components/teacher-modules/TeacherFiles.jsx`

**Change:**
- Remove "Upload File" button
- Keep only file listing/viewing functionality
- This section becomes "reference materials only"

---

## 🎯 Key Features Summary

### **Teacher Experience:**
1. Creates deadline in "Deadlines" tab
2. Attaches instructional materials (PDFs, docs, etc.)
3. System auto-creates submission records for all students
4. Views student submissions organized by deadline
5. Clicks student name to see their work
6. Grades and provides feedback

### **Student Experience:**
1. Sees deadlines in "Deadlines" tab on dashboard
2. Views assignment details and downloads materials
3. Uploads their work files
4. Clicks "Turn In" to submit
5. Can unsubmit before grading
6. Receives grade and feedback from teacher

### **Auto-Features:**
- ✅ Submissions created automatically when deadline posted
- ✅ Late detection when student submits after due date
- ✅ Status tracking: assigned → turned_in → graded
- ✅ Alphabetical student sorting
- ✅ Missing work detection

---

## 📁 File Storage Structure

```
backend/uploads/
├── deadline-files/
│   └── class-{classId}/
│       └── deadline-{deadlineId}/
│           ├── material1.pdf
│           └── material2.docx
└── submission-files/
    └── class-{classId}/
        └── deadline-{deadlineId}/
            └── student-{studentId}/
                ├── work1.pdf
                └── work2.jpg
```

---

## 🔄 Status Flow Diagram

```
TEACHER                          STUDENT
   |                                |
   | Creates Deadline               |
   | + Attaches Materials           |
   |                                |
   v                                |
[System Auto-Creates               |
 Submissions for All Students]     |
   |                                |
   |                         <------| Receives Assignment
   |                                | (status: 'assigned')
   |                                |
   |                                | Views Materials
   |                                | Uploads Work
   |                                | Clicks "Turn In"
   |                                |
   | <----------------------------- |
   |                                |
   | Views Submission               | (status: 'turned_in')
   | Checks if Late                 | [Auto-marked if late]
   | Inputs Grade                   |
   | Writes Feedback                |
   |                                |
   |-----------------------------> |
                                    | (status: 'graded')
                                    | Views Grade & Feedback
```

---

## ✅ Testing Checklist

- [ ] Database tables created successfully
- [ ] Backend API routes working
- [ ] Teacher can create deadline with files
- [ ] Students auto-receive assignment
- [ ] Student can view deadline details
- [ ] Student can upload and submit work
- [ ] Late submissions marked correctly
- [ ] Teacher can view all submissions
- [ ] Teacher can grade submissions
- [ ] Grade appears on student side
- [ ] File uploads/downloads working
- [ ] Alphabetical sorting working
- [ ] Status badges displaying correctly

---

**Next Step:** Run the database SQL, then I'll build all backend routes, then frontend components!
