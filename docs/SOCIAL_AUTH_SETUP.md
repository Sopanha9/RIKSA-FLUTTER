# Google and Telegram authentication setup

The Flutter and Spring Boot code is complete, but provider-owned IDs and bot
credentials must be created in your own Google Cloud and Telegram accounts.
Never commit a bot token, JWT secret, or release signing key.

## 1. Google Cloud

Use one Google Cloud project and configure its OAuth consent screen. Create:

1. A **Web application** OAuth client. This is the common backend audience.
2. An **Android** OAuth client:
   - package: `com.riksa.riksa_app`
   - current local debug SHA-1:
     `D3:AA:29:77:EC:14:49:C7:F1:5A:DF:5C:F6:03:CE:97:5A:EB:FA:FD`
   - add the SHA-1 for the real release/upload key before publishing.
3. An **iOS** OAuth client:
   - bundle ID: `com.riksa.riksaApp`

Set the Web client ID in `../riksa-api/.env`:

```dotenv
GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

For iOS, copy the URL-scheme template and replace its value with the iOS
client's `REVERSED_CLIENT_ID`:

```sh
cp ios/Flutter/GoogleAuth.xcconfig.example ios/Flutter/GoogleAuth.xcconfig
```

Run Android with the Web client ID:

```sh
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Run iOS with both client IDs:

```sh
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID.apps.googleusercontent.com
```

For Flutter web, add the app origin (for example
`http://localhost:7357`) to the Web client's **Authorized JavaScript origins**,
then run:

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

The client sends the Google ID token to `POST /api/v1/auth/google`. The API
returns the Riksa token pair that the app stores in secure storage.

## 2. Telegram bot

1. Open `@BotFather` in Telegram and run `/newbot`.
2. Put the issued values in `../riksa-api/.env`:

```dotenv
TELEGRAM_ENABLED=true
TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN
TELEGRAM_BOT_USERNAME=YOUR_BOT_USERNAME
# Local development (no public HTTPS needed):
TELEGRAM_POLLING_ENABLED=true
```

3. Restart the API after changing `.env`.

Users never enter a Telegram ID. They choose **Open Telegram** (confirm in the
bot) or **Log in with code** (paste the code the bot sends after Start). New
Telegram users then pick a username and display name. See
[`TELEGRAM_AUTH_FLOW.md`](TELEGRAM_AUTH_FLOW.md).

## 3. Start and verify locally

Start the API from `../riksa-api`, then run the app with the Google defines
above. The local API defaults are `http://10.0.2.2:8080` on an Android emulator
and `http://localhost:8080` on iOS/web. Use `--dart-define=API_BASE_URL=...` for
a physical phone or deployed API.

Verify all four paths:

- existing user: Continue with Google;
- new user: Continue with Google (automatic registration);
- Telegram, existing user: Open Telegram → Confirm in bot → Home, and
  Log in with code → paste code → Home;
- Telegram, new user: either option → choose a username and display name → Home.
