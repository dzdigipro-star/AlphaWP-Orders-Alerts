# AlphaWP Orders - Flutter Mobile App

This Flutter project integrates with the AlphaWP Direct Checkout WordPress plugin to provide mobile notifications for new orders and abandoned leads.

## Features

- 🔔 Push notifications for new orders (with cha-ching sound!)
- ⚠️ Alerts for abandoned leads and captcha failures
- 📊 Dashboard with today's stats
- 📋 Order and lead management
- 📞 Click-to-call customers
- 🌓 Dark mode support
- 🏪 Multi-site support

## Setup

### 1. Prerequisites

- Flutter SDK (3.0+)
- Android Studio or VS Code with Flutter extensions
- Firebase project with FCM enabled

### 2. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add an Android app with your package name
4. Download `google-services.json` to `android/app/`
5. Generate a service account key and add it to WordPress

### 3. Install Dependencies

```bash
cd mobile-app
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

### 5. Build Release APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## WordPress Configuration

1. Go to WordPress → AlphaWP Direct Checkout → Mobile App
2. Copy the API Key
3. Enable Push Notifications
4. Paste your Firebase service account JSON
5. Save changes

## App Usage

1. Open the app
2. Enter your WordPress site URL
3. Paste the API Key from WordPress
4. Tap "Connect Store"

You'll start receiving notifications for new orders!

## Sound Assets

Place your custom notification sound at:
```
assets/sounds/cha_ching.mp3
```

If you don't have a custom sound, the app will use the default system sound.

## Project Structure

```
lib/
├── main.dart           # App entry point
├── models/
│   ├── site.dart       # Site/store model
│   ├── order.dart      # Order model
│   └── lead.dart       # Lead model
├── providers/
│   └── app_provider.dart   # App state management
├── screens/
│   ├── login_screen.dart   # Site connection
│   ├── home_screen.dart    # Main dashboard
│   └── settings_screen.dart # App settings
└── services/
    ├── api_service.dart        # REST API client
    └── notification_service.dart # Push notifications
```
