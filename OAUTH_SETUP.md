# Google OAuth Setup for GudMerchant

This document explains how Google OAuth has been implemented in the GudMerchant application and how to configure it properly.

## Configuration Details

The application is set up with the following OAuth credentials:

- **Client ID**: `223085914471-5hud3blon64rcuecapgmbqgieduh99sq.apps.googleusercontent.com`
- **Project ID**: `buoyant-set-457022-f7`

## Implementation Features

1. **Google Sign-In**: Users can sign in using their Google accounts.
2. **Encrypted User Data**: User data is encrypted using bcrypt before being stored for admin review.
3. **Admin Notifications**: Admin receives notifications when users sign up or log in, with encrypted user details.

## How to Test

1. Install and run the application
2. On the welcome screen, click the "Sign in with Google" button
3. Complete the Google authentication flow
4. You will be redirected to the main screen upon successful authentication

## Admin Notifications System

When a user signs up or logs in, their information is:

1. Encrypted using bcrypt
2. Stored in the `admin_notifications` collection in Firestore
3. Each notification includes:
   - User ID (not encrypted)
   - Encrypted user details
   - Activity type (login or signup)
   - Timestamp
   - Processing status flag

## Encryption Details

- Sensitive user data is encrypted using bcrypt before being sent to the admin
- Non-sensitive fields (like userID, isAdmin, etc.) are not encrypted
- Each field is encrypted individually to maintain the data structure

## Troubleshooting

If you encounter issues with Google Sign-In:

1. Verify that the SHA-1 fingerprint of your debug keystore is registered in the Firebase console
2. Ensure that the Google Sign-In API is enabled in your Google Cloud Console
3. Check that your AndroidManifest.xml contains the internet permission
4. Verify that google-services.json is properly configured

## Security Notes

- Never store unencrypted passwords or sensitive user information
- The bcrypt algorithm is used for secure one-way encryption
- Admin should have proper security measures to handle the encrypted data 