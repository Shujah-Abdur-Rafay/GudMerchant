# Admin Panel Documentation

This document explains how the admin panel works in the GudMerchant application, including the user data encryption and decryption functionality.

## Accessing the Admin Panel

By default, only users with admin privileges can access the admin panel. To make yourself an admin:

1. Go to the Settings screen
2. Tap on "App Version" 7 times to enable Developer Options
3. Under Developer Options, tap "Make Current User Admin"
4. You should now see an "Admin Panel" option in your profile menu

## Admin Panel Features

### User Notifications Tab

The Admin Panel includes a Notifications tab that shows all user login and signup events. For each event, you can see:

- The user ID
- The encrypted user details
- The timestamp of the activity
- Whether it was a login or signup event
- Option to mark notifications as processed

### Encryption and Decryption

The application implements two-way encryption for sensitive user data:

1. **Encryption**: User data is encrypted using AES encryption before being stored in Firestore
2. **Decryption**: In the admin panel, you can toggle between viewing encrypted and decrypted data using the lock/unlock button

## Implementation Details

### Encryption System

- The `EncryptionHelper` class provides methods for encrypting and decrypting data
- AES encryption is used for two-way encryption (encryption/decryption)
- Bcrypt is used for password hashing (one-way)
- Non-sensitive fields (UIDs, timestamps, etc.) are not encrypted

### Data Flow

1. When a user signs up or logs in, their details are encrypted using AES
2. The encrypted data is stored in the `admin_notifications` collection in Firestore
3. Admins can view this data and decrypt it as needed
4. After reviewing a notification, admins can mark it as processed

## Security Considerations

- The AES encryption key is stored in the application code for demo purposes
- In a production environment, you should use a secure key management solution
- Always ensure that user privacy is maintained and that you comply with relevant data protection regulations
- Limit admin access to trusted individuals

## Technical Notes

- Encryption is performed using the `encrypt` package with AES algorithm
- Each field is encrypted individually to maintain the data structure
- The toggle button in the admin panel lets you switch between viewing encrypted and decrypted data 