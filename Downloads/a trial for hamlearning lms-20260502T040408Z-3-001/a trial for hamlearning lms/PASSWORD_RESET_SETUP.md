# Password Reset Feature Setup

## Overview
The forgot password feature has been implemented with the following flow:
1. User clicks "Forgot password?" on login page
2. User enters their email address
3. System sends a password reset email with a secure token
4. User clicks the link in the email
5. User sets a new password
6. User can now login with the new password

## Database Setup

Run the following SQL in your Supabase SQL Editor to add the required columns:

```sql
-- Add password reset columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP WITH TIME ZONE;
```

Or simply run the entire `database-setup.sql` file which includes these columns.

## Email Configuration

### Option 1: Gmail (Recommended for Testing)

1. **Enable 2-Factor Authentication** on your Gmail account

2. **Create an App Password**:
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Name it "HamLearning LMS"
   - Copy the 16-character password

3. **Create `.env` file** in the `backend` folder:
   ```
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your-16-char-app-password
   ```

4. **Install dotenv** (if not already installed):
   ```bash
   cd backend
   npm install dotenv
   ```

5. **Update server.js** to load environment variables (add at the top):
   ```javascript
   require('dotenv').config();
   ```

### Option 2: Other Email Services

You can modify `backend/routes/password-reset.js` to use other email services:

**SendGrid:**
```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);
```

**Mailgun, AWS SES, etc.** - Update the transporter configuration accordingly.

## Testing the Feature

### Test Flow:

1. **Start both servers:**
   ```bash
   # Backend
   cd backend
   npm start

   # Frontend (new terminal)
   cd frontend
   npm run dev
   ```

2. **Navigate to login page** (http://localhost:3000)

3. **Click "Forgot password?"** link

4. **Enter your email** (must be registered in the system)

5. **Check your email** for the reset link

6. **Click the reset link** - it will take you to http://localhost:3000/reset-password?token=...

7. **Enter new password** (minimum 6 characters)

8. **Login with new password**

## API Endpoints

### POST /api/password/forgot-password
Request password reset email
```json
{
  "email": "user@example.com"
}
```

### POST /api/password/reset-password
Reset password with token
```json
{
  "token": "reset-token-from-email",
  "newPassword": "newpassword123"
}
```

### GET /api/password/verify-reset-token/:token
Check if reset token is valid

## Security Features

✅ Reset tokens expire after 1 hour  
✅ Tokens are random 32-byte cryptographically secure strings  
✅ Passwords are hashed with bcrypt before storage  
✅ Email validation prevents enumeration attacks  
✅ Google OAuth accounts are protected from password resets  
✅ Tokens are cleared after successful password reset  

## Troubleshooting

### "Failed to send email"
- Check your EMAIL_USER and EMAIL_PASSWORD in .env
- Make sure you're using an App Password, not your regular Gmail password
- Verify 2-factor authentication is enabled on your Gmail account

### "Invalid or expired reset token"
- Reset tokens expire after 1 hour - request a new one
- Make sure you're using the complete token from the email URL

### "This account uses Google Sign-In"
- Users who signed up with Google OAuth cannot reset their password
- They should use Google to log in

## Production Considerations

For production deployment:

1. **Use a dedicated email service** (SendGrid, Mailgun, AWS SES)
2. **Update reset URL** in `password-reset.js` to your production domain
3. **Set longer token expiry** if needed (currently 1 hour)
4. **Customize email template** with your branding
5. **Add rate limiting** to prevent abuse
6. **Enable email verification** for new signups

## Files Created/Modified

**Backend:**
- `backend/routes/password-reset.js` - Password reset routes
- `backend/server.js` - Added password reset routes
- `backend/.env.example` - Email configuration template
- `database-setup.sql` - Added reset_token columns

**Frontend:**
- `frontend/src/components/ForgotPassword.jsx` - Forgot password form
- `frontend/src/components/ForgotPassword.css` - Styling
- `frontend/src/components/ResetPassword.jsx` - Reset password form
- `frontend/src/components/Signup.jsx` - Added forgot password navigation
- `frontend/src/App.jsx` - Added /reset-password route
