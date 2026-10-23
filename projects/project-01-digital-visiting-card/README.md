# Project 1 — Digital Visiting Card

Digital Visiting Card is a Flutter app for presenting a professional profile,
sharing contact details, and helping people save a vCard from a QR code. It was
built for the CognoRise InfoTech App Development Internship.

This README describes this application only. The project is intended to live at
`projects/project-01-digital-visiting-card` in the
[CognoRise-InfoTech repository](https://github.com/AMETOWOSI/CognoRise-InfoTech).

## Project status

| Check | Status |
| --- | --- |
| Home, About, Skills, Contact, and Edit Profile screens | Implemented |
| Navigation with GoRouter | Implemented |
| Local profile storage | Implemented with `shared_preferences` |
| Contact QR code | Generated from the current profile as a vCard |
| Portfolio and social links | Optional and validated before opening |
| Automated tests | Passed: 13 tests with `flutter test` |
| Static analysis | Passed with `flutter analyze` |
| Android debug build | Passed with `flutter build apk --debug` |
| Real-device persistence check | Recommended before submission |
| Android release signing | Not configured; set up a private release key before distribution |

Automated tests use an in-memory repository for widget flows. They verify
application behavior without depending on a real Android or iOS storage
process. Follow the device check below to verify persistence after fully
closing and reopening the app.

## What you can do

- View a digital profile card with a consistent white, purple, and yellow
  visual identity.
- Navigate between Home, About, Skills, and Contact screens.
- Edit profile and contact details.
- Save profile data locally on the current device.
- Scan a QR code to import the profile as a vCard contact.
- Open email, telephone, WhatsApp, portfolio, Facebook, LinkedIn, and
  Instagram links when those details are provided.
- Use the app on narrow mobile screens and wider layouts.

The application does not include accounts, a backend, or synchronization
between devices.

## Security and privacy

The app does not intentionally send profile data to an application server.
Profile values are stored locally using `shared_preferences`. This is
convenient key-value storage, not encrypted storage. Do not store passwords,
authentication codes, or other highly sensitive information in the profile.

The QR code is visible to anyone who can see the screen. It contains the
profile's contact details, job and company information, location, introduction,
and valid portfolio or social URLs. Review those fields before sharing the QR
code.

A static security review did not identify a verified exploitable vulnerability
in the reviewed application code and platform configuration. A query of the
56 resolved Dart package versions against the OSV advisory database returned
no known advisories on 2026-10-23. These checks are not a guarantee of
security; review dependency advisories and release settings again before
publishing. Dart's installed `pub` command does not provide a `pub audit`
subcommand.

Android debug builds remain available for development. A release signing key
is deliberately not included in this repository. Configure a private
production signing key and replace the example Android application ID before
distributing a release build. Do not commit keystore files or passwords.

## Run locally

Install Flutter and Android Studio or VS Code with the Flutter and Dart
extensions. Start an Android emulator or connect a device, then run:

```shell
flutter pub get
flutter devices
flutter run
```

To run static analysis and automated tests:

```shell
flutter analyze
flutter test
```

To build an Android debug APK:

```shell
flutter build apk --debug
```

To target a particular connected device:

```shell
flutter run -d <device-id>
```

## Personalize the sample profile

The initial example profile is defined in
[`lib/profile/models/profile.dart`](lib/profile/models/profile.dart). Use
**Edit profile** in the app to replace the sample values. The profile is saved
on the current device and is not sent to a server.

Scan the QR code with a second phone and confirm that the expected contact
fields are offered for import. Portfolio and social URLs are optional; invalid
or empty URLs are omitted.

## Verify persistence on a real device

1. Start the app on an emulator or phone.
2. Change a profile value and save it.
3. Close the app completely; do not only navigate to another screen.
4. Launch the app again.
5. Confirm that the saved value is still displayed.
6. Repeat with a contact link and scan the QR code to verify its vCard data.

This checks the platform storage implementation in addition to the mocked
storage used by the automated widget tests.

## How the code is organized

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── app_colors.dart
└── profile/
    ├── data/
    │   └── profile_repository.dart
    ├── models/
    │   └── profile.dart
    ├── screens/
    │   ├── about_screen.dart
    │   ├── contact_screen.dart
    │   ├── edit_profile_screen.dart
    │   ├── home_screen.dart
    │   └── skills_screen.dart
    ├── state/
    │   └── profile_controller.dart
    ├── utils/
    │   ├── external_launcher.dart
    │   ├── profile_link_utils.dart
    │   └── vcard_builder.dart
    └── widgets/
        └── page_scaffold.dart

test/
├── profile_test.dart
└── widget_test.dart
```

The app configuration owns the theme and GoRouter routes. `ProfileController`
loads and saves profile state through `ProfileRepository`. Screens render that
shared state, while the link utilities and vCard builder keep URI and contact
formatting out of the UI layer.

### Profile update flow

1. The edit form validates the entered values.
2. The form creates an updated `Profile` model.
3. `ProfileController` saves the model through the repository.
4. The repository encodes the model as JSON and writes it to local
   preferences.
5. The screens rebuild from the updated controller state.

### Contact QR flow

1. `buildVCard` creates a vCard from the current profile.
2. Optional web links are checked before inclusion.
3. `qr_flutter` renders the vCard string as a QR code on the Home screen.
4. A contact application can scan the code and offer to import its fields.

## Dependencies

- [`go_router`](https://pub.dev/packages/go_router) provides declarative
  navigation.
- [`qr_flutter`](https://pub.dev/packages/qr_flutter) renders the contact QR
  code locally.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) stores
  the single-device profile.
- [`url_launcher`](https://pub.dev/packages/url_launcher) opens contact links
  in external applications.
- [`font_awesome_flutter`](https://pub.dev/packages/font_awesome_flutter)
  provides recognizable social-network icons.

## Tests

The test suite covers profile JSON validation, URL and WhatsApp handling,
vCard generation, controller loading behavior, screen navigation, narrow
layouts, and profile editing.

Run the complete suite from the project directory:

```shell
flutter test
```

## Learning references

The app uses the Flutter
[architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations),
the Dart
[Effective Dart guidelines](https://dart.dev/effective-dart), and the Flutter
[testing overview](https://docs.flutter.dev/testing/overview). For focused
Flutter examples, see
[nisrulz/flutter-examples](https://github.com/nisrulz/flutter-examples). The
reference repository is not copied or included as a dependency.

## License

This project is an educational prototype. The bundled Manrope font is
distributed under the SIL Open Font License; see
[`assets/fonts/OFL.txt`](assets/fonts/OFL.txt). Third-party package licenses
remain those of their respective authors.
