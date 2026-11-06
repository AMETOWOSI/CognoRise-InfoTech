# NoteFlow

NoteFlow is an Android Flutter app for private notes, profile management, and
AI-assisted conversations. Firebase Authentication, Cloud Firestore, Firebase
Storage, and Firebase AI Logic provide its cloud-backed features.

## Project status

| Check | Status |
| --- | --- |
| Email/password authentication and account recovery | Implemented |
| Notes CRUD and live Firestore synchronization | Implemented |
| Account profile photo upload and cross-device loading | Implemented; requires Firebase Storage setup |
| Chat history and shared read-only snapshots | Implemented; Firestore rules must be deployed |
| Gemini chat | Implemented; Firebase AI Logic and App Check must be configured |
| Local note reminders | Implemented for Android; not synchronized |
| Automated tests | Passed: 21 tests with `flutter test` |
| Static analysis | Passed with `flutter analyze` |
| Android debug build | Passed with `flutter build apk --debug` |
| Production signing | Not configured; do not distribute a debug build |

## Features

- Sign up and sign in with email and password.
- Keep the Firebase session between app launches.
- Create, edit, search, and delete notes.
- Sync each user's notes in real time at `users/{uid}/notes`.
- Set a one-time reminder for a note using an on-device Android notification.
- Keep each signed-in user's chat history private and synchronized in Firestore.
- Continue a saved Gemini conversation with recent multi-turn context.
- Create read-only share links for selected conversations; owners can revoke
  links, and deleting a conversation also removes its shared copy.
- Upload a profile photo to the account's private Firebase Storage path and
  show it on the Notes home screen after signing in on another device.
- Update the account display name, request an email change, and change the
  password from **Account information**.
- Set a display name during sign-up; it is saved to Firebase Authentication
  and shown on the Notes page.
- Use the provided NoteFlow logo in the sign-in screen and Android launcher.
- Open **Account information** from the profile icon on either app tab.
- Use the same blue theme on authentication, notes, account information, and AI
  chat.

Profile photos are stored at `users/{uid}/profile/avatar` in Firebase Storage.
The Storage rules restrict SDK reads and writes to the authenticated owner and
limit uploads to image files of at most 5 MB. Firebase download URLs contain a
bearer token; treat the account's photo URL as private and do not publish it.
Firebase Storage currently requires the Blaze pay-as-you-go plan for this
project; a billing account is required, and usage beyond any applicable free
allowance can incur charges. The app does not upload a photo until the user
selects one.

Note reminders are scheduled locally on the device and are not synchronized.
Android may deliver them a little later to save battery, and the app asks for
notification permission when a reminder is first set. The notification bell
remains an empty-state view. Push notifications when notes change on another
device are deferred; they require a Firebase Messaging/Functions backend and
the Blaze billing plan to deploy Cloud Functions.

## Firebase project setup

This app is currently configured for the Firebase project `notes-cloud-a9ea8`,
Android app ID `com.example.project_06_notes_app_cloud_sync_ai_chatbot`, and
Firestore location `nam5`.

The app logo is stored at `assets/branding/notes_app_logo.png`. If replacing
the Android launcher artwork, update that source image and regenerate the
launcher resources with `dart run flutter_launcher_icons`.

1. In Firebase Console, confirm **Authentication → Sign-in method → Email/Password**
   is enabled.
2. Confirm Cloud Firestore is created in the `nam5` multi-region. Chat history
   and notes are denied until the current `firestore.rules` are published.
3. Set up Firebase Storage:
   - In Firebase Console, open **Databases & Storage → Storage** and create
     the default bucket. Storage requires the Blaze plan. The generated bucket
     for this project is `notes-cloud-a9ea8.firebasestorage.app`.
   - Review `storage.rules`; it grants access only to the matching signed-in
     UID and restricts uploads to images no larger than 5 MB.
4. Deploy the Firestore and Storage rules and Firebase Hosting configuration
   from the project root in PowerShell:

   ```powershell
   firebase use notes-cloud-a9ea8
   firebase deploy --only firestore:rules,storage,hosting
   ```

   The rules keep notes, saved chats, and profile images within each owner's
   UID. They allow public read-only access only to individual shared-chat IDs;
   listing the `sharedChats` collection is denied. Deploying enables the public
   share capability, so do not deploy until you are ready for recipients with
   a link to read those specific conversations.

4. The Android App Links file at
   `hosting/.well-known/assetlinks.json` currently contains this machine's
   **debug** signing fingerprint. Before distributing a production release,
   add the Play App Signing SHA-256 fingerprint to the file and deploy Hosting
   again. The release build must be signed with the matching private key; never
   commit or share the private signing key.

5. In Firebase Console, open **AI Services → AI Logic** (the menu wording may
   vary), enable Firebase AI Logic, and choose a supported Gemini provider.
   The app uses `gemini-3.8-flash`. Select **Gemini Developer API** to start;
   this model is listed as not requiring billing. Do not generate or add a
   Gemini API key to the app.
6. App Check is initialized in the app. For debug builds, it uses the Android
   debug provider:
   - Install and run the **debug** build on the exact phone being tested:
     `flutter run -d DEVICE_ID`.
   - In another PowerShell window, run `adb logcat -s DebugAppCheckProvider`,
     then restart the app. Find the line saying **“Enter this debug secret into
     the allow list”**.
   - In Firebase Console, ensure the selected project is
     `notes-cloud-a9ea8`. Open **Security → App Check → Apps**, select the
     Android app with package
     `com.example.project_06_notes_app_cloud_sync_ai_chatbot`, choose **Manage
     debug tokens**, and register the secret from that phone.
   - Do not register an App Check JWT or a token copied from another phone or
     emulator. After registering, wait a few minutes, force-stop and reopen the
     debug app, then retry AI chat.
   - Keep the token private; do not commit it or put it in source control.
7. For a production release, register the Android app with Play Integrity in
   App Check and distribute a properly signed release build. Play Integrity
   attestation is automatic for supported installs; users do not register debug
   tokens. A local debug build always uses a debug token, and each debug
   installation must be registered separately. Do not disable App Check or ship
   a debug provider to avoid this requirement.

### Diagnosing chat permission errors

- **“Firestore denied this chat-history request”** means the app could not
  create/read its private chat document. Confirm the user is signed in to
  `notes-cloud-a9ea8` and deploy the current `firestore.rules` using the
  command above. Do not make chat history public to work around this error.
- **“Firebase AI Logic denied this request”** means the Gemini request was
  rejected. Confirm AI Logic and the Gemini Developer API are enabled, then
  check **Security → App Check → APIs → Firebase AI Logic**. Register the
  current device's debug token for a debug build, or use a correctly
  Play-signed release with Play Integrity. Firestore rules do not fix an
  App Check or Gemini provider rejection.

## Passwords and account recovery

- Sign-up and password changes require at least 8 characters, including an
  uppercase letter, a lowercase letter, a number, and a symbol.
- For server-side enforcement, configure the same requirements in Firebase
  Console under **Authentication → Settings → Password policy**. Client-side
  validation alone is not an enforcement boundary.
- **Forgot password?** sends Firebase Authentication's password-reset email.
  Configure the email template and authorized domains under Firebase
  Authentication before testing the reset link.
- CAPTCHA and OTP are not currently added. For this app, use Firebase Auth's
  password policy, rate limiting, email recovery, and App Check (Play Integrity
  in production) first. Add an interactive CAPTCHA or second factor only if
  abuse or account-risk requirements justify the added friction.

If you change Firebase project or Android application ID, re-run
`flutterfire configure` and verify `lib/firebase_options.dart` and
`android/app/google-services.json`.

## Run on a physical Android phone over Wi-Fi

For Android 11 (API 30) or newer, Wireless debugging pairs the phone and
computer without a USB cable:

1. Connect the phone and computer to the same Wi-Fi network. Avoid guest
   networks that isolate devices; temporarily turn off a VPN if it blocks local
   device connections.
2. On the phone, enable **Developer options** (if needed, tap **Build number**
   seven times under **About phone**), then open **Developer options →
   Wireless debugging** and turn it on.
3. Choose **Pair device with pairing code**. Keep the pairing dialog open and
   note the displayed IP address, pairing port, and pairing code.
4. In PowerShell, pair with the pairing port shown on the phone:

   ```powershell
   adb pair PHONE_IP:PAIRING_PORT
   ```

   Enter the pairing code when prompted. Replace the uppercase placeholders
   with the values shown on your phone.
5. Return to the main **Wireless debugging** screen and find its current
   **IP address and port**. This connection port is different from the pairing
   port. If Flutter does not discover the paired phone automatically, connect
   using that port:

   ```powershell
   adb connect PHONE_IP:DEVICE_PORT
   flutter devices
   flutter run -d PHONE_IP:DEVICE_PORT
   ```

   Use the device ID printed by `flutter devices` if it differs from
   `PHONE_IP:DEVICE_PORT`. The pairing is usually remembered; the phone and
   computer must still be on the same network and Wireless debugging must be
   enabled.
6. To disconnect when finished:

   ```powershell
   adb disconnect PHONE_IP:DEVICE_PORT
   ```

If the phone runs Android 10 or older, use ADB-over-TCP as a fallback. This
method requires connecting a USB cable once to enable it:

```powershell
adb devices
adb tcpip 5555
adb connect PHONE_IP:5555
flutter devices
flutter run -d PHONE_IP:5555
```

Find `PHONE_IP` in the phone's Wi-Fi network details. If connection fails,
check that the phone and computer are on the same non-isolated network and that
Windows Firewall allows Android SDK Platform Tools on the private network.

## Run over USB (alternative)

1. Install Android Studio / Android SDK and Flutter, and enable **Developer
   options → USB debugging** on the phone.
2. Connect the phone with a data-capable USB cable and accept the phone's
   debugging authorization prompt.
3. From PowerShell in this project folder, check that Flutter sees the device:

   ```powershell
   flutter devices
   ```

4. Install dependencies and launch the debug app:

   ```powershell
   flutter pub get
   flutter run
   ```

   The phone needs an internet connection to contact Firebase. `flutter run`
   installs the debug build on the selected device. If multiple devices are
   listed, add `-d DEVICE_ID` using the ID printed by `flutter devices`.
5. Register the App Check debug token from that physical device in Firebase
   Console as described above. A debug token is specific to the installation;
   reinstalling the app may produce a different token.

## Test the real Firebase services

### Authentication

1. Confirm Email/Password sign-in is enabled in Firebase Console.
2. Run the app on the phone, create a test account, and confirm the account
   appears under **Authentication → Users**.
3. Sign out from **Account information**, sign in again, then close and reopen
   the app to verify session persistence.
4. In **Account information**, save a display name. Try an email change using
   the current password and confirm the verification link delivered to the new
   email address. Test a password change with the current password, then sign
   in again with the new password.

### Cloud Firestore and real-time sync

1. Publish `firestore.rules` using the deploy commands above.
2. Sign in on the phone and create a note.
3. In Firebase Console, open **Firestore Database → Data** and verify the
   document is under `users/{the signed-in user's UID}/notes`.
4. Sign in on a second device with the same account. Create or edit a note on
   either device and confirm the other device updates without restarting.
5. Sign in with a different account and confirm it cannot see the first
   account's notes.
6. In **AI chat**, send a prompt, start another conversation, then open
   **Chat history** and return to the first one. Verify the list and messages
   reappear after restarting the app and on a second device signed into the
   same account. A different account must not see them.

### Local note reminders

1. Open a note, choose **Set** beside **No reminder**, select a future date and
   time, and allow Android notifications when prompted.
2. Save the note. Confirm it appears in Android's notification settings under
   **NoteFlow** and that the reminder arrives at the scheduled time. Android may
   defer inexact reminders while the device is idle.
3. Edit the note to change or clear the reminder. Delete the note on another
   device and confirm its local reminder is canceled after Firestore sync.
4. Reminders are stored on this device only. Reinstalling the app or clearing
   its data removes them; another device will not schedule the same reminder.

### Profile photo

Create the Storage bucket and deploy `storage.rules` first. Choose **Add profile
photo** in **Account information**; the image uploads to the signed-in user's
Storage path. The Notes home screen loads the same photo from Firebase after
the user signs in on another device or reinstalls the app. Each upload is
limited to 5 MB. Removing the photo deletes it from Storage and clears the
account's profile image.

### Firebase AI Logic

1. Enable AI Logic and the selected Gemini provider in Firebase Console.
2. For a debug build, register the physical device's App Check debug token.
   Production Play Integrity builds do not use debug tokens.
3. Open **AI chat**, send a simple prompt, then send a follow-up that refers to
   the previous answer. Confirm both prompts work in one conversation, then
   reopen that conversation from **Chat history**.
4. If the chat reports an error, check Firebase Console's AI Logic setup,
   App Check token registration (debug only), network access, and the
   Android/Flutter run logs. Messages are only synchronized after they are
   successfully saved to Firestore.

### Conversation sharing

1. Deploy both Firestore rules and Hosting as described in Firebase setup.
   This makes each explicitly shared conversation publicly readable by anyone
   who has its unlisted link. The share is read-only and does not require the
   recipient to sign in.
2. In **AI chat → Chat history**, use **Share link** and confirm the warning.
   Open the link on another device with NoteFlow installed; the app should show
   the shared conversation in read-only mode.
3. Use **Revoke share link** or delete the original conversation. Verify the
   link no longer opens. Deleting a conversation also removes its shared copy.
   The link is a snapshot: messages added later are not included. To publish an
   updated snapshot, revoke the existing link first, then create a new one.
4. On the released Android app, App Links require the correct Play App Signing
   SHA-256 fingerprint in `hosting/.well-known/assetlinks.json`. Without it,
   the web landing page still offers the `noteflow://` fallback.

## Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

`pnpm` is not used to manage Flutter app dependencies. It can be used to install
Node.js tools such as Firebase CLI; Flutter packages are managed by `flutter
pub`.

## Code layout

- `lib/services/`: Firebase Authentication, Firestore, and Firebase AI Logic.
- `lib/providers/`: authentication, notes, and chat state.
- `lib/models/`: note and chat message models.
- `lib/screens/`: authentication, password recovery, notes, account information,
  AI chat, and read-only shared chats.
- `lib/theme/` and `lib/widgets/`: shared app styling and reusable UI.
- `firestore.rules`: owner-only notes and chat history plus read-only shared
  conversation rules.
- `storage.rules`: owner-only profile photo access and upload validation.

Push notifications for notes are not implemented; the notifications control
currently opens an empty-state message.
