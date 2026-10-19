# Simple Push Notification Messaging App (Flutter + Firebase)

A clean, modern, beginner-friendly Flutter & Firebase push notification messaging application. This project enables an authorized sender to compose a message, choose one or multiple registered devices, and securely dispatch push notifications using Firebase Cloud Messaging (FCM) and server-side Firebase Cloud Functions.

---

## 1. Project Overview & Architecture

### Core Principles
- **Target Platform**: Android (primary target), iOS and Web supported.
- **Security First**: Client applications **never** embed Firebase Admin SDK service account keys or privileged credentials. Push notification dispatch is delegated entirely to a secure server-side Firebase Cloud Function (`sendPushNotification`).
- **Persistent Device Identity**: Receiver devices are stored in Cloud Firestore under the `devices` collection with a persistent installation identifier stored in `SharedPreferences`, avoiding issues when rotating FCM registration tokens.
- **Centralized Theming**: 100% of styling tokens (colors, border radius, borders, spacing, typography, dimensions, theme extensions) reside in `lib/core/theme/`. No scattered ad-hoc styles.

---

## 2. Project Directory Structure

```text
push_notification_apps/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts          # Android app build configuration & Google services plugin
│   │   └── src/main/
│   │       └── AndroidManifest.xml   # FCM permissions & notification channel meta-data
│   └── settings.gradle.kts           # Gradle plugin management
│
├── functions/
│   ├── package.json                  # Firebase Cloud Functions dependencies (firebase-admin, firebase-functions)
│   └── index.js                      # Secure sendPushNotification v2 callable Cloud Function
│
├── lib/
│   ├── main.dart                     # App entry point, FCM initialization & device registration
│   ├── app.dart                      # MaterialApp configuration with themes and routing
│   ├── firebase_options.dart         # FlutterFire configuration options
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart    # Collections, channel IDs, function names, limits
│   │   │
│   │   ├── routes/
│   │   │   ├── app_routes.dart       # Route string names ('/' and '/devices')
│   │   │   └── route_generator.dart  # MaterialPageRoute generation logic
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart        # Full Light & Dark ThemeData definitions
│   │   │   ├── app_colors.dart       # Cohesive color palette (primary indigo, status colors)
│   │   │   ├── app_radius.dart       # Small, medium, large, circular border radii
│   │   │   ├── app_borders.dart      # Reusable input and card borders
│   │   │   ├── app_spacing.dart      # 4/8-pt grid spacing tokens & EdgeInsets/SizedBox helpers
│   │   │   ├── app_text_styles.dart  # Display, headline, title, body, label, caption styles
│   │   │   ├── app_dimensions.dart   # Heights, icon sizes, max-widths
│   │   │   └── app_theme_extensions.dart # Semantic AppCustomColors theme extension
│   │   │
│   │   ├── services/
│   │   │   ├── firebase_service.dart # Firebase core init, anonymous auth & device UUID
│   │   │   ├── fcm_service.dart      # FCM permissions, tokens, background & foreground handlers
│   │   │   └── notification_service.dart # flutter_local_notifications heads-up display
│   │   │
│   │   ├── utils/
│   │   │   └── validators.dart       # Title, body, and device selection validation rules
│   │   │
│   │   └── widgets/
│   │       ├── app_button.dart       # Reusable button with variants & loading indicator
│   │       ├── app_text_field.dart   # Themed text field with label, hints & error styles
│   │       ├── app_loading_indicator.dart # Centered spinner with optional message
│   │       └── app_error_view.dart   # Compact and full error state views with retry
│   │
│   └── features/
│       ├── sender/
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   └── notification_model.dart     # Payload model & delivery history
│       │   │   └── repositories/
│       │   │       └── notification_repository.dart # Invokes Cloud Function & logs dispatches
│       │   └── presentation/
│       │       ├── screens/
│       │       │   └── sender_screen.dart          # Primary message composer & device selector
│       │       └── widgets/
│       │           ├── message_form.dart           # Title, body input fields & send button
│       │           └── device_selector.dart        # Checkbox selection with "Select All"
│       │
│       └── devices/
│           ├── data/
│           │   ├── models/
│           │   │   └── device_model.dart           # Device metadata & Firestore mapping
│           │   └── repositories/
│           │       └── device_repository.dart      # Device registration & real-time streams
│           └── presentation/
│               ├── screens/
│               │   └── devices_screen.dart         # Status card & registered receiver devices
│               └── widgets/
│                   └── device_list_tile.dart       # Device info card, masked token & status
│
├── firebase.json                     # Firebase tools & emulator configuration
├── firestore.rules                   # Granular Firestore security rules
├── firestore.indexes.json            # Firestore composite index definitions
├── pubspec.yaml                      # Flutter dependencies and assets
└── README.md                         # Complete documentation
```

---

## 3. Firebase Configuration Procedure

### Step 1: Create a Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project**, name it (e.g., `simple-push-app`), and click **Continue**.
3. Google Analytics can be toggled on or off based on your preference, then click **Create project**.

### Step 2: Enable Firebase Services in the Console
1. **Firebase Authentication**:
   - In the left sidebar, navigate to **Build > Authentication**.
   - Click **Get started**.
   - Under the **Sign-in method** tab, enable **Anonymous** (required for client identification) and optionally **Email/Password**.
2. **Cloud Firestore**:
   - Navigate to **Build > Firestore Database**.
   - Click **Create database**, select a region close to your users (e.g., `us-central1`), and start in **Production mode** (our `firestore.rules` will protect the collections).
3. **Firebase Cloud Messaging (FCM)**:
   - FCM is enabled by default on all Firebase projects.
4. **Firebase Cloud Functions**:
   - Navigate to **Build > Functions**.
   - Click **Get started**. Note: Cloud Functions requires the Firebase **Blaze (Pay as you go)** plan. Google provides a generous free monthly tier (2 million invocations per month free).

### Step 3: Install Firebase CLI & FlutterFire CLI
Ensure Node.js (v18+) and Flutter SDK are installed, then run in your terminal:
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

### Step 4: Configure Flutter Project with FlutterFire
Run this command from the project root (`d:\push_notification_apps`):
```bash
flutterfire configure
```
1. Select your Firebase project from the list.
2. Select target platforms: `android`, `ios` (use spacebar to select/deselect).
3. Press **Enter**. This automatically:
   - Registers your Android app package `com.example.push_notification_apps`.
   - Downloads `android/app/google-services.json`.
   - Generates/overwrites `lib/firebase_options.dart` with your real project keys.

---

## 4. Backend Deployment (Cloud Functions & Firestore Rules)

### Step 1: Install Functions Dependencies
```bash
cd functions
npm install
cd ..
```

### Step 2: Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

### Step 3: Deploy Cloud Functions
The backend includes 4 secure server-side functions:
1. `registerDevice`: Receives FCM token and device metadata, deduplicates tokens, and writes to `devices`.
2. `updateDeviceToken`: Updates the device record on token refresh and invalidates duplicates.
3. `getRegisteredDevices`: Retrieves the active device list for authorized senders.
4. `sendPushNotification`: Verifies sender authorization and dispatches multicast notifications via Firebase Admin SDK.

```bash
firebase deploy --only functions
```

### Local Testing with Firebase Emulators (Optional)
If you prefer testing locally without deploying live Cloud Functions:
```bash
firebase emulators:start
```

---

## 5. Authorizing the Initial Sender

To prevent unauthorized users from sending notifications, `functions/index.js` checks the `authorized_senders` collection.

### Automatic Bootstrap (Development Mode)
- When the first user opens the application and sends a message, `functions/index.js` detects that `authorized_senders` is empty and **auto-authorizes** the first caller as an admin sender.

### Manual Authorization (Production Mode)
In the Firebase Console > **Firestore Database**:
1. Create a collection named `authorized_senders`.
2. Add a document whose **Document ID** is the sender's Firebase Auth `UID`.
3. Add fields:
   - `uid` (string): `<user_uid>`
   - `isAuthorized` (boolean): `true`
   - `role` (string): `"admin_sender"`

---

## 6. Running the App

### To run on a connected Android phone or emulator:
```bash
flutter pub get
flutter run
```

### To run on a specific target device:
```bash
flutter devices
flutter run -d <DEVICE_ID>
```

---

## 7. Instructions for Testing Push Notifications Across Two Phones

To test real push notifications between two phones:

### Setup
1. **Device A (Receiver)**: Install and launch the app.
   - When prompted, grant notification permissions.
   - The device will generate a unique ID, obtain its FCM registration token, and save its details in Firestore under `devices`.
   - Keep Device A open, or minimize it to test background handling.
2. **Device B (Sender)**: Install and launch the app.
   - Device B will load the list of registered devices from Firestore.
   - You will see Device A in the **Target Devices** list (identified with its model name, e.g., "Samsung SM-S918B" or "Pixel 8").

### Test Scenario 1: Foreground Notification
1. Keep the app **open and active on Device A**.
2. On **Device B**, select Device A from the list, enter a title (e.g. `Server Alert`) and message body (e.g. `Database backup completed successfully.`), then tap **Send Push**.
3. Device A will display a heads-up local notification banner with title and body.

### Test Scenario 2: Background Notification
1. Press the **Home button on Device A** to send the app to the background.
2. On **Device B**, compose a message and tap **Send Push**.
3. Device A will receive an Android system tray notification.

### Test Scenario 3: Terminated State Notification & Tap Interaction
1. **Swipe away / kill the app on Device A** from the recent apps switcher.
2. On **Device B**, send a notification.
3. Device A will show the system notification in the status bar.
4. Tapping the notification on Device A will launch the app and trigger the notification tap callback.

---

## 8. Troubleshooting Guide

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Notification not appearing in foreground** | Local notifications channel not created or notification permission denied | Ensure permission was accepted in Android 13+ dialog. Verify channel ID `simple_push_channel` in `AndroidManifest.xml`. |
| **Notification not arriving in background/killed state** | Battery optimization killing background FCM service | On Android, go to **Settings > Apps > Simple Push > Battery > Unrestricted**. |
| **`sendPushNotification` fails with `unauthenticated`** | Firebase Auth anonymous sign-in failed | In Firebase Console, go to **Authentication > Sign-in method** and ensure **Anonymous** provider is enabled. |
| **`sendPushNotification` fails with `permission-denied`** | Sender UID not in `authorized_senders` | Check `authorized_senders` collection in Firestore. Ensure document with sender's UID has `isAuthorized: true`. |
| **Token expired or invalid message** | App was uninstalled and reinstalled | Launch app on receiver device; the app will generate a fresh token and update Firestore automatically. |
| **Cloud Functions deploy error: Billing not enabled** | Firebase free Spark plan doesn't support Cloud Functions deployment | Upgrade project to **Blaze Plan (Pay as you go)** in Firebase Console. 2 million function invocations per month are free. |
#   p u s h _ n o t i f i c a t i o n _ a p p s  
 