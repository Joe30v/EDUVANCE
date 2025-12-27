# eduvance

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase setup (added by automation)

This project now includes Firebase Core and Firebase Auth and basic integration
for login, sign up, and password reset.

Steps to finish platform setup:

1. Create a Firebase project at https://console.firebase.google.com/
2. Add an Android app (use your Android package name) and download `google-services.json`.
   - Place `google-services.json` in `android/app/`.
   - Follow Firebase console steps to add the Android app; ensure you add the SHA-1 if you plan to use Google sign-in.
   - In `android/build.gradle` add the Google services classpath and apply plugin as instructed by Firebase.
3. Add an iOS app in the Firebase console and download `GoogleService-Info.plist`.
   - Place `GoogleService-Info.plist` in `ios/Runner/`.
   - Run `pod install` in `ios/` (or run `flutter run` which will trigger CocoaPods install).
4. Run `flutter pub get` to fetch the added packages (`firebase_core` and `firebase_auth`).

Notes:
- Initialization is done in `lib/main.dart` with `Firebase.initializeApp()`.
- `lib/AuthPage.dart` now uses `FirebaseAuth` for sign in and sign up.
- `lib/ForgotPasswordPage.dart` uses `FirebaseAuth.sendPasswordResetEmail` and navigates to the success page on success.
- I added the Google Services Gradle plugin to `android/build.gradle.kts` and applied it in `android/app/build.gradle.kts` so `google-services.json` will be processed when you add it.

If you want, I can also add an Auth state UI (showing current user and Sign out button) and automated configuration to place platform files; I still cannot create the Firebase project or download the platform files for you — you'll need to provide them or add them to the repo and I will finish the configuration steps.

---

## Password reset

The in-app reset flow (including the `/functions` server reset-code flow and the in-app reset screen) has been removed. The app still supports the standard Firebase password reset email workflow via `lib/ForgotPasswordPage.dart` which sends a password-reset email using `FirebaseAuth.sendPasswordResetEmail`.

If you want server-driven reset codes or deep-link based in-app reset again in the future, I can re-add an implementation on request.

---


---

## Platform deep links / App Links / Universal Links (setup)

1. Choose and own the domain to use for links (e.g., `reset.yourdomain.com`). You must be able to host files under `https://<your-domain>/.well-known/`.
2. Host the iOS `apple-app-site-association` file at `https://<your-domain>/.well-known/apple-app-site-association` (no .json extension). Use the sample in `docs/apple-app-site-association.sample.json` and replace `<TEAM_ID>` and `<BUNDLE_ID>`.
3. Host the Android `assetlinks.json` file at `https://<your-domain>/.well-known/assetlinks.json`. Use the sample in `docs/assetlinks.sample.json` and replace the SHA-256 fingerprint and package name.
4. iOS: In Xcode, open `Runner` target -> Capabilities -> Associated Domains and add `applinks:<your-domain>`.
5. Android: In `android/app/src/main/AndroidManifest.xml` add the intent-filter (example is included as a commented block), and rebuild the app. If you host the verification file correctly, the system will verify App Links and allow `autoVerify`.
6. Test: Build the app on device and open a link (https://<your-domain>/path?oobCode=XYZ). The app should open and navigate to the Reset Password screen with the code prefilled.

If you need, I can generate the exact `apple-app-site-association` and `assetlinks.json` content once you provide the domain, Apple Team ID, and Android signing cert fingerprint.
