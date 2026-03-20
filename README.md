# SafeLink

## Secure Firebase Setup

This app uses Firebase client configuration at runtime. Client API keys are not
private secrets, but they must still be protected with strict restrictions and
backend rules.

### 1. Keep config files out of git

Do not commit these files:

- `firebase_config.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

Use `firebase_config.template.json` as the template for your local
`firebase_config.json`.

### 2. Run with local dart defines

Create `firebase_config.json` from the template and fill values locally.

Run:

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

- Keep Firestore rules strict (never open `allow read, write: if true`).
- Enable Firebase App Check for Firestore/Auth/Storage where supported.
- Put privileged operations in Cloud Functions, not in client code.

## Notes

- Android can still initialize from `google-services.json` if present locally.
- Even when keys are not in git, client apps can still be decompiled; security
  must rely on rules, App Check, and key restrictions.
