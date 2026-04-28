# SafeLink - Emergency Alert App

SafeLink is a comprehensive, real-time emergency alert and personal safety application built with Flutter. It provides immediate, full-screen emergency notifications and customizable accessibility features to ensure users can receive and send SOS alerts effectively under any circumstance.

## Key Features & App Screens

- **Authentication & Security**: Secure login and registration flows utilizing Firebase Authentication.
- **Home Dashboard**: A central hub providing quick access to emergency features, recent alerts, and app settings.
- **SOS Management**:
  - **Quick SOS Trigger**: Dedicated SOS tab and screen to immediately send out distress signals.
  - **Setup SOS Contacts**: Manage personal emergency contacts and trusted individuals.
- **Real-Time Full-Screen Emergency Alerts**: Bypasses standard notification behavior to display a high-priority, system-level overlay when a nearby critical alert is received, even if the app is in the background.
- **Interactive Map & Location Tracking**: Live real-time location tracking and map view utilizing `flutter_map` and `geolocator` to see nearby incidents and share your position.
- **Accessibility & Stealth Modes**:
  - Granular controls for "Vibration Only" and "Silent SOS" modes, natively integrating with Android's Ringer Mode.
  - Built-in support for Live Caption alerts for deaf or hard-of-hearing individuals.
- **Notifications & Alert Details**: A dedicated notification center to review past alerts and detailed screens for active emergency events.
- **User Profiles**: Manage personal details, medical information, and application settings.
- **Admin Dashboard**: Specialized screens for administrators to monitor active alerts, manage system users, and oversee the platform's safety metrics.
- **Firebase Integration**: Secure backend powered by Cloud Firestore for real-time data sync, Cloud Storage for media, and Firebase Cloud Messaging (FCM) for push notifications.

## Technology Stack

- **Framework**: Flutter (Dart `^3.10.7`)
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore, Messaging, Storage)
- **Maps & Location**: `flutter_map`, `geolocator`
- **Device Integrations**: `flutter_local_notifications`, `sound_mode`, `flutter_volume_controller`

---

## Secure Firebase Setup

This app uses Firebase client configuration at runtime. Client API keys are not private secrets, but they must still be protected with strict restrictions and backend rules.

### 1. Keep config files out of git

Do not commit these files:
- `firebase_config.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

Use `firebase_config.template.json` as the template for your local `firebase_config.json`.

### 2. Run with local dart defines

Create `firebase_config.json` from the template and fill in the values locally.

Run the app using:
```bash
flutter run --dart-define-from-file=firebase_config.json
```

### 3. Rotate and restrict API keys

In Google Cloud Console -> APIs & Services -> Credentials:
- Rotate keys that were previously exposed.
- Restrict Web key by HTTP referrers.
- Restrict Android key by package name + SHA certificate.
- Restrict iOS key by bundle ID.
- Apply API restrictions to required Firebase APIs only.

### 4. Enforce Firebase security controls

- Keep Firestore rules strict (never use `allow read, write: if true`).
- Enable Firebase App Check for Firestore/Auth/Storage where supported.
- Put privileged operations in Cloud Functions, not in client code.

## Notes

- Android can still initialize from `google-services.json` if present locally.
- Even when keys are not in git, client apps can still be decompiled; security must rely on rules, App Check, and key restrictions.

## Building and Running

1. Ensure you have Flutter installed and configured.
2. Clone the repository and navigate to the project directory.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Set up your local `firebase_config.json`.
5. Run the application:
   ```bash
   flutter run --dart-define-from-file=firebase_config.json
   ```
