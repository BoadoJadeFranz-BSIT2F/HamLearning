# Team Development Guide - HamLearning LMS

## 🎯 Module Structure

Each team member works on their own module independently. All modules are located in:
```
frontend/src/components/modules/
```

### Available Modules:
1. **Dashboard** (DashboardHome.jsx) - Join classes page
2. **Schedules** (Schedules.jsx) - Class schedules and timetables
3. **Deadlines** (Deadlines.jsx) - Assignment and project deadlines
4. **Analytics** (Analytics.jsx) - Performance insights and statistics
5. **Grades** (Grades.jsx) - Grades and GPA tracking
6. **Tasks** (Tasks.jsx) - To-do lists and task management
7. **Pomodoro** (Pomodoro.jsx) - Focus timer
8. **Wellness** (Wellness.jsx) - Mental and physical wellness tracking

## 🚀 How to Work on Your Module

### 1. Find Your Module File
Navigate to `frontend/src/components/modules/YourModule.jsx`

### 2. Replace the Placeholder
The file currently has placeholder content. Replace everything with your implementation:

```javascript
import React from 'react';
import './Module.css'; // You can create your own CSS file too

const YourModule = () => {
  // Your component logic here

  return (
    <div className="module-container">
      {/* Your UI here */}
    </div>
  );
};

export default YourModule;
```

### 3. Shared Resources Available

#### Access Dashboard Context:
```javascript
import { useOutletContext } from 'react-router-dom';

const YourModule = () => {
  const { onClassJoined, refreshTrigger } = useOutletContext();
  
  // Use these to interact with the dashboard
};
```

#### Access User Info:
```javascript
import { useAuth } from '../../context/AuthContext';

const YourModule = () => {
  const { user } = useAuth();
  // user contains: email, name, role, etc.
};
```

#### Make API Calls:
```javascript
import { classAPI, authAPI } from '../../services/api';

// Examples:
const classes = await classAPI.getEnrolledClasses();
const userData = await authAPI.verify();
```

## 📁 File Organization

### Create Your Own Files:
```
modules/
├── YourModule.jsx          # Your main component
├── YourModule.css          # Your styles (optional)
├── YourModuleHelper.js     # Helper functions (optional)
└── Module.css              # Shared styles (already exists)
```

### Module.css Classes Available:
- `.module-container` - Main container
- `.module-header` - Header section with title
- `.module-content` - Content area
- `.module-description` - Description text

## 🔄 Navigation

Users navigate between modules via the green submenu bar. The page **does NOT reload** - it's a Single Page Application (SPA).

Routes:
- `/dashboard` → Dashboard (Join Classes)
- `/dashboard/schedules` → Your Schedules
- `/dashboard/deadlines` → Your Deadlines
- etc.

## 🛠️ Development Workflow

### 1. Pull Latest Code
```bash
git pull origin main
```

### 2. Create Your Branch
```bash
git checkout -b feature/your-module-name
```

### 3. Work on Your Module
- Edit only YOUR module file
- Test your changes locally
- Make sure navigation still works

### 4. Test Your Module
```bash
cd frontend
npm run dev
```
Visit `http://localhost:3000/dashboard/your-module`

### 5. Commit Your Changes
```bash
git add src/components/modules/YourModule.jsx
git commit -m "Implemented YourModule feature"
git push origin feature/your-module-name
```

### 6. Create Pull Request
- Go to GitHub
- Create PR from your branch to `main`
- Ask for code review

## 🎨 Styling Guidelines

### Colors:
- Primary Green: `#2d7a4f`
- Dark Green: `#1e5a3a`
- Light Green: `#e8f5e9`
- Text Dark: `#1a1a1a`
- Text Gray: `#666`

### Keep Consistency:
- Use similar header styles across modules
- Match the overall HamLearning design
- Test on both light backgrounds

## ⚠️ Important Rules

1. **DON'T modify** shared files without team discussion:
   - Dashboard.jsx
   - Navbar.jsx
   - SubMenu.jsx
   - App.jsx

2. **DO modify** freely:
   - Your own module file
   - Your own CSS file
   - Your own helper files

3. **Test your module** before committing

4. **Communicate** with team about shared dependencies

## 💾 Database Integration

If your module needs database tables, follow these steps:

### 1. Design Your Schema
```sql
CREATE TABLE your_table (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  -- your columns here
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Add to Supabase
Run your SQL in Supabase SQL Editor

### 3. Create Backend API Route
Create `backend/routes/your-module.js`:
```javascript
const express = require('express');
const router = express.Router();
const supabase = require('../config/supabase');

router.get('/your-endpoint', async (req, res) => {
  // Your logic
});

module.exports = router;
```

### 4. Register Route in server.js
```javascript
const yourModuleRoutes = require('./routes/your-module');
app.use('/api/your-module', yourModuleRoutes);
```

### 5. Add to Frontend API
In `frontend/src/services/api.js`:
```javascript
export const yourModuleAPI = {
  getData: () => api.get('/your-module/your-endpoint'),
  // more methods...
};
```

## 🤝 Getting Help

- Check existing modules for examples
- Ask in team chat
- Review the main Dashboard and JoinClass components
- Check React Router docs for navigation
- Test frequently!

## ✅ Checklist Before PR

- [ ] Module displays correctly
- [ ] Navigation works (can switch to other modules)
- [ ] No console errors
- [ ] Follows design guidelines
- [ ] Code is commented
- [ ] Tested on Chrome/Firefox
- [ ] Committed only your module files

---

**Happy Coding! 🎓✨**
