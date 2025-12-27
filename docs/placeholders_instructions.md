# Placeholder verification files

This folder contains placeholder files for App Links / Universal Links verification.

Files:
- `apple-app-site-association.placeholder` — copy to your host and rename to `apple-app-site-association` then upload to `https://<your-domain>/.well-known/apple-app-site-association`.
- `assetlinks.placeholder.json` — update placeholders and upload to `https://<your-domain>/.well-known/assetlinks.json`.

How to fill placeholders:
- Apple Team ID: Found in your Apple Developer account -> Membership.
- Bundle ID: Xcode -> Runner target -> General -> Bundle Identifier.
- Android package name: `android/app/src/main/AndroidManifest.xml` -> `package` attribute in `<manifest>`.
- Android SHA-256 fingerprint: Use `keytool -list -v -keystore <your-keystore> -alias <alias>` or get from Play Console for release key.

After hosting these files, ensure you:
- Enable Associated Domains in Xcode: `applinks:<your-domain>`
- Un-comment and set the Android intent-filter in `android/app/src/main/AndroidManifest.xml` and rebuild.

Testing:
- Build the app on device and open a link like `https://<your-domain>/?oobCode=XYZ`. The app should open and the Reset Password screen should prefill the code.

If you want, I can generate the exact content for you if you provide the real values.
