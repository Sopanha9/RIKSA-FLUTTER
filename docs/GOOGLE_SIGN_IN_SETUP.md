# Google Sign-In setup

Last checked: 2026-09-30

This app uses the `google_sign_in` Flutter plugin. It sends Google's **ID token**
to `POST /api/v1/auth/google`; the Riksa API must verify the token against the
same Web OAuth client ID used as the app's server audience.

> Sign-in uses OAuth client IDs, not a Google API key. A client ID is public
> app configuration. Never put a Web client secret in Flutter, a `--dart-define`,
> or this repository.

## What I checked

- The selected Cloud project is **RIKSA**, project ID `riksa-509418`.
- The project has three Android OAuth clients, one Web OAuth client, and the
  iOS OAuth client created during this setup; no API key is needed for this
  sign-in flow.
- Android's actual application ID and `MainActivity` package are both
  `com.riksa.riksa_app`.
- iOS's actual bundle ID is `com.riksa.riksaApp`.
- Two older Android OAuth clients are registered as `com.riksa.riksaApp`, which
  is the iOS bundle ID and does not match Android. The package update I tried
  failed with `Requested entity already exists`. I found and restored the
  previously deleted **RIKSA** Android client, which already matches the debug
  build: package `com.riksa.riksa_app` and the debug SHA-1 below. That exact
  package/SHA-1 pair was the duplicate blocking the attempted update.
- The restored debug Android OAuth client ID is
  `141117277134-tjrbm2gmofi8nge4r81aipjvatu667l2.apps.googleusercontent.com`.
- The current debug SHA-1 is
  `A6:01:1D:CC:58:1B:71:09:12:B0:94:9B:88:55:D1:FB:03:65:15:C9`. The older
  `D3:AA:...` value previously listed in `SOCIAL_AUTH_SETUP.md` was stale.
- The Web OAuth client now allows `http://localhost` and
  `http://localhost:7357` as Authorized JavaScript origins. The Flutter Web run
  command below uses port `7357`.
- OAuth audience is **External / Testing**. One approved tester has been added;
  Google blocks sign-in for accounts that are not on the test-user list while
  the app is in Testing.
- The iOS OAuth client is
  `141117277134-gm97ocnsctu36i9p7pfe7b07kukd64nr.apps.googleusercontent.com`
  for bundle ID `com.riksa.riksaApp`. Its reversed ID is
  `com.googleusercontent.apps.141117277134-gm97ocnsctu36i9p7pfe7b07kukd64nr`.

## What I checked in GitHub Actions

The `staging` GitHub environment currently has:

- `GOOGLE_SERVER_CLIENT_ID` set to the existing Web client ID. This is correct
  for the ID-token audience used by Android and the backend.
- `GOOGLE_IOS_CLIENT_ID` now points to the iOS client for bundle ID
  `com.riksa.riksaApp`. It previously held the Web client ID.
- `GOOGLE_WEB_CLIENT_ID` now exists and points to the existing Web client. It
  was previously absent; the Flutter fallback masked the omission locally, but
  the workflow passes this variable explicitly.
- Android signing secrets are present. The workflow builds a release APK and
  uses the environment keystore when those secrets are populated. The secret
  values were not opened. Register the release keystore's SHA-1 in Google Cloud
  in addition to the local debug fingerprint. One existing Cloud Android client
  has a different SHA-1 from local debug; verify whether it matches the staging
  keystore before relying on it.

All three staging OAuth variables now point to the correct client type. The
restored Android client matches this computer's debug build. Verify the release
keystore SHA-1 separately before relying on the staging Android APK.

## Cloud Console changes made

In Google Cloud project **RIKSA** (`riksa-509418`):

- Added the approved tester under **Audience → Test users**. The app remains in
  Testing, so each person who needs access must be listed there.
- Added `http://localhost` and `http://localhost:7357` as Authorized JavaScript
  origins on the existing **Riksa Web** OAuth client. The Flutter sign-in flow
  uses a JavaScript origin; it does not need an Authorized redirect URI.
- Created the iOS OAuth client for bundle ID `com.riksa.riksaApp`.
- Restored the deleted Android OAuth client named **RIKSA**. It has package
  `com.riksa.riksa_app` and the exact local debug SHA-1 recorded above, so it
  supports this computer's debug Android build. The two older Android clients
  remain registered with the wrong package. Google notes that changes may take
  5 minutes to a few hours to take effect.
- Updated the GitHub `staging` environment: `GOOGLE_IOS_CLIENT_ID` now uses the
  iOS client, and the missing `GOOGLE_WEB_CLIENT_ID` now uses the Web client.
  `GOOGLE_SERVER_CLIENT_ID` was already correct. Android signing secrets were
  left unchanged.

For a Play-distributed Android build, add the SHA-1 fingerprint of the **Play
App Signing certificate** to an Android OAuth client with package
`com.riksa.riksa_app`. For a locally signed release, register that local release
certificate's SHA-1 instead. The debug fingerprint above only applies to
debug-signed builds on this computer.

## Local Flutter run

`.dart-defines.local.json` is a git-ignored local file with the existing Web ID
in `GOOGLE_SERVER_CLIENT_ID` and `GOOGLE_WEB_CLIENT_ID`, and the new iOS ID in
`GOOGLE_IOS_CLIENT_ID`. It contains no client secret. Use it when building or
running the app:

```sh
flutter run --dart-define-from-file=.dart-defines.local.json
```

The command targets the currently configured device. For the Android emulator,
the app's default API URL is `http://10.0.2.2:8080`. Start the Riksa API and make
sure its `GOOGLE_CLIENT_ID` matches the Web OAuth client ID in the local file.

For Flutter Web:

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357 \
  --dart-define-from-file=.dart-defines.local.json
```

For iOS, the local JSON already includes `GOOGLE_IOS_CLIENT_ID`. The ignored
`ios/Flutter/GoogleAuth.xcconfig` file contains the iOS client's reversed ID:

```text
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.141117277134-gm97ocnsctu36i9p7pfe7b07kukd64nr
```

The committed `ios/Flutter/GoogleAuth.xcconfig.example` is the template. The
Flutter iOS build also needs `GOOGLE_SERVER_CLIENT_ID` from the Web client.

## Diagnose a failure

- Android `DEVELOPER_ERROR` / error code 10: compare the installed app's
  `applicationId` and signing SHA-1 with an Android OAuth client. For the
  current local debug build they must be `com.riksa.riksa_app` and the restored
  client's fingerprint recorded above. Check that Google's client changes have
  propagated before retrying.
- Google says the app is in testing or blocks the account: add that account to
  **Audience → Test users**.
- Flutter Web reports an origin/client error: confirm both localhost origins
  above are on the **Web** OAuth client and use port `7357`.
- Google sign-in succeeds but the Riksa API rejects it: set the API's
  `GOOGLE_CLIENT_ID` to the exact Web client ID supplied as
  `GOOGLE_SERVER_CLIENT_ID`.
- iOS says Google sign-in is not configured: use the created iOS client ID,
  pass `GOOGLE_IOS_CLIENT_ID`, and keep its reversed ID in
  `GoogleAuth.xcconfig`.

## References

- [Google Sign-In Android setup](https://developers.google.com/identity/sign-in/android/legacy-gsi-start)
- [Google Cloud OAuth client credentials](https://developers.google.com/identity/protocols/oauth2)
- [Google Identity Services Web setup](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid)
- [Flutter `google_sign_in` 7.2.0 documentation](https://pub.dev/packages/google_sign_in)
