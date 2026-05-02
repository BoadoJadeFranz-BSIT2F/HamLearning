# LMS - Learning Management System

A modern Learning Management System with React frontend and Node.js backend.

## Features

- ✅ User Authentication (Login/Signup)
- ✅ JWT Token-based Security
- ✅ Protected Routes
- ✅ Responsive Design
- ✅ Modern UI with Gradient Theme

## Tech Stack

### Frontend
- React 18
- React Router v6
- Axios for API calls
- Vite for development

### Backend
- Node.js
- Express
- JWT for authentication
- bcryptjs for password hashing

## Getting Started

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn

### Installation

1. **Install Backend Dependencies**
```bash
cd backend
npm install
```

2. **Install Frontend Dependencies**
```bash
cd frontend
npm install
```

### Running the Application

1. **Start the Backend Server**
```bash
cd backend
npm start
```
The backend will run on http://localhost:5000

2. **Start the Frontend Development Server**
```bash
cd frontend
npm run dev
```
The frontend will run on http://localhost:3000

## Usage

1. Open http://localhost:3000 in your browser
2. Click "Sign up" to create a new account
3. Fill in your details (name, email, password)
4. After signup, you'll be automatically logged in
5. You can logout and login again with your credentials

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/verify` - Verify JWT token

## Project Structure

```
├── backend/
│   ├── config/
│   │   └── config.js
│   ├── routes/
│   │   └── auth.js
│   ├── server.js
│   └── package.json
│
└── frontend/
    ├── src/
    │   ├── components/
    │   │   ├── Login.jsx
    │   │   ├── Signup.jsx
    │   │   ├── Dashboard.jsx
    │   │   ├── Auth.css
    │   │   └── Dashboard.css
    │   ├── context/
    │   │   └── AuthContext.jsx
    │   ├── services/
    │   │   └── api.js
    │   ├── App.jsx
    │   ├── main.jsx
    │   └── index.css
    ├── index.html
    ├── vite.config.js
    └── package.json
```

## Future Enhancements

- Course Management
- Lesson Creation and Viewing
- Quiz System
- Progress Tracking
- User Profiles
- Admin Dashboard
- File Uploads
- Discussion Forums

## License

MIT
