# Project 6 — NoteFlow

NoteFlow is a Flutter notes app built for the CognoRise InfoTech App
Development Internship. It combines Firebase Authentication, real-time Cloud
Firestore notes, and a Gemini-powered chat using Firebase AI Logic.

## Project status

| Requirement | Status |
| --- | --- |
| Email/password sign-up, login, recovery, and session persistence | Implemented |
| Notes create, read, update, and delete | Implemented with Cloud Firestore |
| Real-time synchronization of a user's notes | Implemented; verify with two signed-in devices |
| Image attachments on notes using Firebase Storage | Not implemented; the Storage bucket has not been initialized |
| Provider-based app state | Implemented with Provider |
| Authentication errors and form validation | Implemented |
| Gemini chat UI, loading/error states, and multi-turn context | Implemented with Firebase AI Logic |
| Private chat history and optional read-only sharing | Implemented with Cloud Firestore and Firebase Hosting |
| Profile photo | Saved locally per account on the current device; not cloud-synchronized |
| Real-device Firebase and Gemini verification | Requires completing the device-specific setup below |

## Features

- Create an account with a display name, email, and password.
- Sign in, keep the Firebase session, and request a password-reset email.
- Create, edit, search, and delete notes stored under the signed-in user's
  Firestore account.
- Receive real-time note updates from Firestore.
- Set local Android reminders for notes.
- Save a small profile photo in the app's private storage on the current
  device. The home screen displays it above the account name.
- Chat with Gemini, continue a conversation with recent context, and revisit
  saved chat history.
- Optionally create, share, revoke, and open read-only conversation links.
- Use a consistent English interface and shared visual theme.

## Requirements

- Flutter SDK and Dart version compatible with the constraint in
  [`pubspec.yaml`](./pubspec.yaml).
- Android Studio or Visual Studio Code with the Flutter and Dart extensions.
- An Android emulator or physical Android device.
- A Firebase project configured as described below.

## Run locally

Run these commands from the directory containing `pubspec.yaml`:

```sh
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

Replace `DEVICE_ID` with the identifier reported by `flutter devices`. To let
Flutter choose the only available device, use `flutter run`.

Run the automated checks and create a debug APK:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

## Architecture

- **Flutter / Provider:** screen composition and authentication, notes, and
  chat state.
- **Firebase Authentication:** account creation, sign-in, email/password
  recovery, and the current user session.
- **Cloud Firestore:** owner-scoped notes, chat history, and explicitly shared
  read-only chat snapshots.
- **Firebase AI Logic:** requests to the Gemini Developer API without placing
  a Gemini API key in the Flutter application.
- **App Check:** Android debug attestation while developing and Play Integrity
  attestation for a properly signed production release.
- **Local profile photo:** the selected image is copied into the app-private
  support directory and stored under a local key derived from the Firebase
  user ID. No profile image is uploaded to Firebase.
- **Local reminders:** Android notifications scheduled on the device; they do
  not synchronize to other devices.

### Firestore data layout

```text
users/{uid}/notes/{noteId}
users/{uid}/chats/{chatId}
users/{uid}/chats/{chatId}/messages/{messageId}
sharedChats/{shareId}/messages/{messageId}
```

The Firestore rules restrict private notes and chats to their owner. Shared
conversation snapshots are readable by anyone who has the link; sharing is
optional and read-only.

## Firebase configuration

The app is currently configured for:

- Firebase project: `notes-cloud-a9ea8`
- Android application ID: `com.example.project_06_notes_app_cloud_sync_ai_chatbot`
- Firestore location: `nam5`

If you change the Firebase project or application ID, run `flutterfire
configure` and verify `lib/firebase_options.dart` and
`android/app/google-services.json`.

### Authentication and Firestore

1. In Firebase Console, enable **Authentication → Sign-in method →
   Email/Password**.
2. Create Cloud Firestore in the intended region. The existing project uses
   `nam5`; Firestore locations cannot be changed after database creation.
3. From this project directory, select the Firebase project and publish the
   rules:

   ```sh
   firebase use notes-cloud-a9ea8
   firebase deploy --only firestore:rules
   ```

4. The app validates passwords on-device. For server-enforced password
   requirements, also configure **Authentication → Settings → Password
   policy** in the console.

### Gemini chat and App Check

The app uses Firebase AI Logic with the Gemini Developer API and the
`gemini-3.8-flash` model. A Gemini API key from Google AI Studio is not needed
or embedded in the application.

1. In Firebase Console, enable **Firebase AI Logic** and select the Gemini
   Developer API provider.
2. Under **Security → App Check → APIs**, confirm Firebase AI Logic is
   configured for enforcement. Firebase requires App Check for Firebase AI
   Logic; Firestore rules do not control this check.
3. Run a debug build on the physical test device. Debug builds use the Android
   App Check debug provider. While the app is running, use
   `flutter logs -d DEVICE_ID` and find the
   `DebugAppCheckProvider` token line. Register that exact token in
   **Security → App Check → Apps → Manage debug tokens**. Keep the token
   private.
4. Repeat token registration for each separate debug installation. A debug
   token is not a universal token, and registering one device does not
   authorize every other physical device.
5. For general user installs, register the Android app with Play Integrity in
   App Check, configure the production signing fingerprints, and distribute a
   properly signed release through Google Play. A locally built or sideloaded
   APK is not guaranteed to pass Play Integrity. Never ship a debug build or
   debug token.

The Gemini Developer API currently offers a no-cost tier for supported models,
including the configured Flash model, subject to Google-set quotas, model
availability, and rate limits. These limits can change; a free tier does not
guarantee uninterrupted service. Google currently states that content sent
through its free Gemini API tier may be used to improve its products. Avoid
sending sensitive personal information in prompts and review Google's current
terms before enabling the feature for other users.

### Profile photo storage

Profile photos are local to the current app installation and account:

- The image is saved in app-private storage and shown on the Notes home screen
  above the account name.
- Signing out does not delete the local file. Signing in to the same account
  on the same device shows that account's saved image.
- The image does not transfer to another device. Each device has its own local
  copy.
- Uninstalling the app or clearing its app data removes the image. Local-only
  storage cannot provide recovery after reinstall.

This replaces cloud profile-photo upload and does not require Firebase Storage
or a Storage billing plan.

### Optional chat sharing

To publish the static web page used for share links and configure hosting:

```sh
firebase deploy --only hosting
```

The Firestore rules must also be deployed. Anyone with an active share link can
read its snapshot. Update
`hosting/.well-known/assetlinks.json` with the production Play App Signing
SHA-256 fingerprint before expecting Android App Links to open the released
app directly.

## Manual verification

### Authentication

1. Create a test account and verify it appears in Firebase Authentication.
2. Close and reopen the app, then confirm the account session is restored.
3. Sign out and sign back in. Test password recovery with an email address you
   can access.
4. Try an invalid password and email to verify the app displays a useful error.

### Notes and real-time synchronization

1. Sign in on two devices with the same test account.
2. Create or edit a note on one device; confirm the other device updates
   without restarting.
3. Sign in with a different account and confirm it cannot read the first
   account's notes.
4. Inspect **Firestore Database → Data** and confirm notes are under
   `users/{uid}/notes`.

### Gemini chat

1. Complete Firebase AI Logic setup and App Check registration for the device
   running the debug app, or install the properly Play-distributed release.
2. Send a prompt, then send a follow-up referring to the first response.
3. Open another conversation and return to the first one; confirm chat history
   is restored.
4. If the request is denied, check App Check before changing Firestore rules:
   `403` / `PERMISSION_DENIED` commonly indicates missing or invalid
   attestation. A quota or rate-limit error must be investigated in the Gemini
   API usage/limits dashboard.

### Local profile photo

1. Open **Account information**, choose **Add profile photo**, and select an
   image.
2. Return to Notes and confirm the photo appears above the account name.
3. Restart the app and confirm the local photo is still shown.
4. Sign in to another account on the same device and confirm it does not show
   the first account's photo. Reinstalling the app removes locally saved
   photos.

## Known limitations

- Image attachments on notes are not implemented. They require a note data
  model and UI for attachments, secure Storage rules, and a configured
  Firebase Storage bucket. Firebase's current Flutter setup requires the
  pay-as-you-go Blaze plan to create a bucket; review region-specific free
  quotas and possible charges before enabling it.
- Profile photos are not cloud-synchronized and cannot survive app removal.
- Gemini calls require valid App Check attestation. Development debug tokens
  must be registered per test installation; production users require a
  correctly configured Play Integrity release.
- Gemini free-tier limits and data-use terms are set by Google and can change.
- Note reminders are local to one Android device. Push notifications for
  changes made on another device are not implemented.
- Android release signing is not configured in this repository.
- Real Firebase service behavior must be verified with the console setup and
  physical devices; automated widget tests do not prove cloud connectivity.

## Project structure

```text
.
├── android/
├── assets/
│   └── branding/
├── hosting/
├── lib/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   └── widgets/
├── test/
├── firestore.rules
├── firebase.json
└── pubspec.yaml
```

## References

- [FlutterFire](https://github.com/firebase/flutterfire)
- [Firebase AI Logic for Flutter](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter)
- [Protect Gemini API with App Check](https://firebase.google.com/docs/ai-logic/app-check)
- [Gemini API pricing and free-tier terms](https://ai.google.dev/gemini-api/docs/pricing)
- [Cloud Storage for Firebase pricing](https://firebase.google.com/pricing)
- [Google Gemini cookbook](https://github.com/google-gemini/cookbook)

## License

No `LICENSE` file is provided. This repository does not specify a license for
reuse or redistribution.
