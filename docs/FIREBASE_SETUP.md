# Firebase Setup Guide

This guide walks you through setting up Firebase for the Pharmacy app.

## Step 1: Create Firebase Project (Browser)

1. **Go to Firebase Console:** https://console.firebase.google.com/
2. **Click "Add project"** or "Create a project"
3. **Enter project name:** `pharmacy-app` (or your preferred name)
4. **Click Continue**
5. **Google Analytics:** You can disable it for now (optional)
6. **Click "Create project"** and wait (~30 seconds)
7. **Click "Continue"** when ready

## Step 2: Enable Realtime Database

1. In your Firebase project, click **"Build"** in the left sidebar
2. Click **"Realtime Database"**
3. Click **"Create Database"**
4. **Location:** Choose closest to you (e.g., `us-central1`)
5. **Security rules:** Start in **"Test mode"** (we'll update rules later)
6. Click **"Enable"**

Your database URL will be: `https://pharmacy-app-xxxxx.firebaseio.com/`

## Step 3: Enable Authentication

1. In the left sidebar, click **"Authentication"**
2. Click **"Get started"**
3. Click on **"Email/Password"** provider
4. **Enable** the toggle
5. **Email link (passwordless sign-in):** Leave disabled
6. Click **"Save"**

## Step 4: Register Android App

1. In Project Overview, click the **Android icon** (robot)
2. **Android package name:** `com.example.pharmacy_app` (must match your app)
   - Find it in: `android/app/build.gradle` → `applicationId`
3. **App nickname:** `Pharmacy App` (optional)
4. **Debug signing certificate SHA-1:** Leave blank for now
5. Click **"Register app"**

### Download google-services.json

6. Click **"Download google-services.json"**
7. **Save the file** - we'll move it next

### Move google-services.json to Project

**Option A: Using File Explorer**
- Copy `google-services.json` from your Downloads folder
- Paste into: `c:\src\Pharmacy\android\app\`

**Option B: Using PowerShell**
```powershell
Move-Item "$env:USERPROFILE\Downloads\google-services.json" "c:\src\Pharmacy\android\app\" -Force
```

8. Click **"Next"** in Firebase Console
9. Click **"Next"** again (we'll configure this via code)
10. Click **"Continue to console"**

## Step 5: Register iOS App (If targeting iOS)

1. In Project Overview, click the **iOS icon** (Apple)
2. **iOS bundle ID:** `com.example.pharmacyApp` (must match your app)
   - Find it in: `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`
3. **App nickname:** `Pharmacy App` (optional)
4. Leave other fields blank
5. Click **"Register app"**

### Download GoogleService-Info.plist

6. Click **"Download GoogleService-Info.plist"**
7. **Save the file**

### Add to Xcode (Mac only)

If you have a Mac:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click `Runner` folder
3. Select **"Add Files to Runner"**
4. Select `GoogleService-Info.plist`
5. Ensure **"Copy items if needed"** is checked
6. Click **"Add"**

If you don't have a Mac yet, you can do this later.

8. Click **"Next"** in Firebase Console
9. Click **"Next"** again
10. Click **"Continue to console"**

## Step 6: Configure Android for Firebase

Edit `android/build.gradle.kts`:

Add to the `plugins` block at the top:
```kotlin
plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false  // ADD THIS
}
```

Edit `android/app/build.gradle.kts`:

Add to the `plugins` block at the top:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ADD THIS
}
```

## Step 7: Verify Setup

Run the verification command:

```powershell
cd c:\src\Pharmacy
flutter run
```

Look for these lines in the console:
```
[FIREBASE] FlutterFire: Initialized successfully
```

If you see errors about `google-services.json` not found, verify it's in:
```
c:\src\Pharmacy\android\app\google-services.json
```

## Step 8: Get Your Firebase Configuration (For Flutter)

You'll need these values from Firebase Console:

1. Go to **Project Settings** (gear icon)
2. Scroll down to **"Your apps"**
3. Click on your Android app
4. Copy these values:

```
API Key: AIza...
Project ID: pharmacy-app
App ID: 1:123456789:android:abc...
Messaging Sender ID: 123456789
Database URL: https://pharmacy-app-xxxxx.firebaseio.com/
Storage Bucket: pharmacy-app.firebasestorage.app
```

Save these - we'll use them in the Flutter code.

## Step 9: Initialize Firebase in Flutter

This has been done for you. The code in `lib/main.dart` will initialize Firebase.

## Troubleshooting

### Error: "google-services.json not found"

**Fix:**
```powershell
# Verify file exists
Test-Path "c:\src\Pharmacy\android\app\google-services.json"

# Should return: True
```

If False, re-download from Firebase Console and move it to `android/app/`.

### Error: "Execution failed for task ':app:processDebugGoogleServices'"

**Fix:** Ensure `android/app/build.gradle.kts` has the Google Services plugin:
```kotlin
id("com.google.gms.google-services")
```

### Error: "Default FirebaseApp is not initialized"

**Fix:** Ensure `main.dart` calls:
```dart
await Firebase.initializeApp();
```

### Gradle build fails

**Fix:** Try:
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## Next Steps

Once Firebase is set up and verified:
1. ✅ Firebase project created
2. ✅ Realtime Database enabled
3. ✅ Authentication enabled
4. ✅ Android app registered
5. ✅ Configuration files added
6. ✅ Flutter dependencies installed

**You're ready to start coding!** The next phase is implementing the Firebase service layer.

## Useful Links

- **Firebase Console:** https://console.firebase.google.com/
- **FlutterFire Docs:** https://firebase.flutter.dev/
- **Realtime Database Docs:** https://firebase.google.com/docs/database/flutter/start
- **Firebase Auth Docs:** https://firebase.google.com/docs/auth/flutter/start
