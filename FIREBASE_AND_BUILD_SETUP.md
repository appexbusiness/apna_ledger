# Apna Ledger — Native setup (Firebase, flavors, Google Sign-In, FCM, biometric)

Everything in `lib/` is wired. The steps below are the **machine-side** work
that can only be done after the platform folders exist. Do them once.

> Product = **Apna Ledger**  ·  Parent = **Appex Business**
> QA package  = `com.appexbusiness.apnaledgerqa`
> Prod package = `com.appexbusiness.apnaledger`

---

## 0. Generate platform folders, icons, splash
```bash
flutter create --org com.appexbusiness --platforms=android,ios,web .
flutter pub get
dart run flutter_launcher_icons          # app icons (android/ios/web) from the logo
dart run flutter_native_splash:create    # branded native splash
```

## 1. Firebase config files
Two projects already exist: **apnaledgerqa** (QA/UAT) and **apnaledger-38818** (Prod).
The Android configs you provided are staged in `assets/firebase/`:

- `assets/firebase/google-services-qa.json`   → package `com.appexbusiness.apnaledgerqa`
- `assets/firebase/google-services-prod.json` → package `com.appexbusiness.apnaledger`

The cleanest way to wire everything (recommended) is the FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=apnaledgerqa        --out=lib/firebase_options_qa.dart   --ios-bundle-id=com.appexbusiness.apnaledgerqa   --android-package-name=com.appexbusiness.apnaledgerqa
flutterfire configure --project=apnaledger-38818    --out=lib/firebase_options_prod.dart --ios-bundle-id=com.appexbusiness.apnaledger     --android-package-name=com.appexbusiness.apnaledger
```
(That regenerates the two `firebase_options_*.dart` and drops the native files in
place. The hand-filled options already in the repo work for web + Android now.)

## 2. Android build flavors (QA vs Prod package names)
In **android/app/build.gradle**, inside `android { }`:
```gradle
flavorDimensions "env"
productFlavors {
    qa {
        dimension "env"
        applicationId "com.appexbusiness.apnaledgerqa"
        resValue "string", "app_name", "Apna Ledger QA"
    }
    prod {
        dimension "env"
        applicationId "com.appexbusiness.apnaledger"
        resValue "string", "app_name", "Apna Ledger"
    }
}
```
Place the flavor-specific Firebase files:
```
android/app/src/qa/google-services.json     <- google-services-qa.json
android/app/src/prod/google-services.json   <- google-services-prod.json
```
Apply the Google-services + Crashlytics Gradle plugins:
- **android/build.gradle** (project) → `dependencies { classpath 'com.google.gms:google-services:4.4.2'; classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2' }`
- **android/app/build.gradle** (top) → `apply plugin: 'com.google.gms.google-services'` and `apply plugin: 'com.google.firebase.crashlytics'`

Run flavored builds / installs:
```bash
flutter run   --flavor qa   -t lib/main_qa.dart
flutter build appbundle --flavor prod -t lib/main_prod.dart --no-tree-shake-icons
```

## 3. iOS
- Add **GoogleService-Info.plist** per scheme (QA/Prod) — easiest via `flutterfire configure`.
- Set bundle ids `com.appexbusiness.apnaledgerqa` / `com.appexbusiness.apnaledger`
  in Xcode schemes (Runner → Signing & Capabilities), add **Push Notifications**
  + **Background Modes → Remote notifications** capabilities.
- `ios/Runner/Info.plist` — add for biometrics & Google:
  ```xml
  <key>NSFaceIDUsageDescription</key><string>Unlock Apna Ledger</string>
  ```
  Add the Google reversed-client-id URL scheme (from GoogleService-Info.plist).

## 4. Enable Firebase services (console)
For **both** projects (Build → …):
- **Authentication** → Sign-in method → enable **Google** (already done for QA per your note) and **Phone** (uses your master OTP `123456` locally for now).
- **Firestore** → created in **asia-south1 (Mumbai)**, production mode. Replace the
  default deny-all rules with app rules **once you switch `kBackend` to firebase**,
  e.g. user-scoped access:
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{uid}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
  ```
  (Your current `allow read, write: if false;` blocks everything — keep the app on
  the default **local** backend until rules + real auth are in.)
- **Analytics**, **Crashlytics** → on by default once the app runs; no extra code.
- **Cloud Messaging** → no console step; tokens print to logs on first run.

## 5. Google Sign-In (OAuth)
- **Android**: add your signing **SHA-1 / SHA-256** (debug + release) to each Firebase
  project → Project settings → your Android app. Re-download `google-services.json`.
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
- **Web**: copy the **Web client ID** into `web/index.html`:
  `<meta name="google-signin-client_id" content="XXXX.apps.googleusercontent.com">`
- The in-app **"Continue with Google"** button then works and routes users to the
  phone + OTP step (phone stays compulsory).

## 6. Biometric (Face/Fingerprint/PIN)

This is the #1 cause of "I tap the App Lock switch and nothing happens" — the
plugin call throws a native error before it ever reaches Dart. `android/` and
`ios/` don't exist until you run `flutter create ...`, so do this right after:

- **Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`
  (as a sibling of `<application>`, not nested inside it):
  ```xml
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  ```
  Then `android/app/src/main/kotlin/.../MainActivity.kt` **must** extend
  `FlutterFragmentActivity`, not `FlutterActivity` — `local_auth` will silently
  fail to launch the prompt otherwise:
  ```kotlin
  import io.flutter.embedding.android.FlutterFragmentActivity

  class MainActivity: FlutterFragmentActivity()
  ```
  And the app's theme (`android/app/src/main/res/values/styles.xml`) must be a
  material/AppCompat theme, or the prompt throws too.

- **iOS** — `ios/Runner/Info.plist` needs `NSFaceIDUsageDescription` (already
  shown above). No extra entitlement is required for Touch ID/passcode.

- Toggle is in **Settings → Security → App lock**. As of this update, the app
  now shows a real reason when it fails (not enrolled / locked out / missing
  permission) instead of silently doing nothing — so once the two Android
  steps above are done, if it still fails the on-screen message will say why.

## 5b. Plugging in a real OTP/SMS provider

`lib/core/services/otp_service.dart` now owns all OTP logic (generation,
5-minute expiry, 30s resend cooldown, and a hard **3 sends/day per number**
cap) — it's independent of the auth backend. The only thing left to wire up
is actual delivery:

1. Implement `SmsGateway.send()` for your provider (MSG91, Fast2SMS, Twilio
   Verify, etc.) — see `ProductionSmsGateway` in that file for a template
   with the exact spot to drop in your HTTP call.
2. In `lib/core/di/injector.dart`, change `smsGatewayProvider` from
   `DebugConsoleSmsGateway()` to your implementation.

Until step 2 is done, every environment (including prod builds) just logs the
OTP to the console instead of sending a real SMS — so QA keeps working, but
**don't ship to real users until this is wired up**.

## 6b. "Dynamic Links shuts down soon" banner in Firebase Console

Safe to ignore for this app. That banner only affects projects using
**email-link sign-in** (`sendSignInLinkToEmail`) or **Cordova OAuth on web** —
this codebase uses neither (auth is mobile+password, stored in Firestore/local
storage directly, plus Google Sign-In via the `google_sign_in` package, which
doesn't touch Dynamic Links). Nothing to change here.

## 7. Switch to the Firebase backend (when ready)
In `lib/core/di/injector.dart` set `const kBackend = Backend.firebase;`
(only after Firestore rules + Auth are live), then transactions/categories sync
to Firestore instead of local storage.

---

## Google Sign-In on WEB — required meta tag (do this!)

`web/index.html` only exists after `flutter create`. Once it does, add ONE of
these lines inside `<head>` (the `google_sign_in` web plugin reads it):

**QA web build** (default `lib/main.dart` uses the QA project):
```html
<meta name="google-signin-client_id"
      content="839704694234-ab4qoiviae2orjj192vagkkpatgp0s0s.apps.googleusercontent.com">
```

**Production web build:**
```html
<meta name="google-signin-client_id"
      content="934702390982-a37o8ahtdh700h50qk0ma5qbvh836qlj.apps.googleusercontent.com">
```

Without this tag you'll see the `client_id not set` / `signIn discouraged` console
messages and the button won't complete. After adding it, hard-refresh.

Also, on the console errors you saw:
- `Cross-Origin-Opener-Policy would block window.closed` and the
  `content-people.googleapis.com 403` are **harmless** — they're the popup-flow
  and profile-photo fetch; sign-in still returns name + email.
- The `signIn is deprecated on web` warning is expected with the current plugin;
  it still works. (A future `renderButton` migration removes the warning.)

## Enable Firestore data
1. Firebase console → **Authentication → Sign-in method → Anonymous → Enable**
   (both projects). The app signs in anonymously so Firestore rules
   (`allow read, write: if request.auth != null;`) pass.
2. The app already runs on the Firebase backend (`kBackend = Backend.firebase`).
   If anonymous auth or Firestore is unreachable, it automatically falls back to
   on-device storage so it never crashes.
