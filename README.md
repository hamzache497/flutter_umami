# umami_flutter

A lightweight, privacy-focused Flutter analytics package powered by [Umami](https://umami.is) — the open-source alternative to Google Analytics and Firebase Analytics.

Track screen views, custom events, and user engagement in your Flutter app **without sending data to Google**. Self-host your analytics, own your data, and stay GDPR-compliant.

[![pub package](https://img.shields.io/pub/v/umami_flutter.svg)](https://pub.dev/packages/umami_flutter)
[![Dart](https://img.shields.io/badge/Dart-%5E3.7.2-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-02569B)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why umami_flutter over Firebase Analytics?

|                              | **umami_flutter**                              | **Firebase Analytics**                              |
| ---------------------------- | ---------------------------------------------- | --------------------------------------------------- |
| **Privacy**                  | ✅ Self-hosted — data never leaves your server | ❌ Data sent to Google servers                      |
| **GDPR compliance**          | ✅ No cookie banners needed, no PII collected  | ⚠️ Requires consent banners and DPA                 |
| **Setup complexity**         | ✅ 3 lines of code, no `google-services.json`  | ❌ Platform config files, Firebase console setup    |
| **Package size**             | ✅ ~9 KB compressed                            | ❌ Firebase core + analytics = significantly larger |
| **Dependencies**             | ✅ Minimal (5 packages)                        | ❌ Heavy dependency tree (Firebase SDK)             |
| **Cost**                     | ✅ Free & open-source (self-hosted)            | ⚠️ Free tier with limits, then paid                 |
| **Data ownership**           | ✅ 100% yours on your own server               | ❌ Stored on Google infrastructure                  |
| **Real-time dashboard**      | ✅ Built-in Umami dashboard                    | ✅ Firebase console                                 |
| **No Google account needed** | ✅                                             | ❌                                                  |
| **Offline queuing**          | ❌ Events dropped offline                      | ✅ Built-in offline support                         |
| **User identity tracking**   | ❌ Privacy-first, no user profiles             | ✅ User properties and audiences                    |

**Best for:** Indie developers, privacy-conscious apps, apps targeting EU markets, and teams that want simple analytics without vendor lock-in.

## Features

- 🚀 **Non-blocking init** — `init()` returns immediately; events tracked before initialization completes are automatically queued and flushed.
- 📱 **Automatic device info** — Collects device ID, locale, and screen resolution out of the box.
- 🔒 **Persistent device IDs** — Uses platform-specific identifiers (Android ID, `identifierForVendor`, etc.) persisted in secure storage (Keychain / EncryptedSharedPreferences) to survive app reinstalls.
- 🔥 **Fire-and-forget tracking** — `trackScreen` and `trackEvent` never block the UI thread.
- 🖥️ **Multi-platform** — Supports Android, iOS, macOS, and Windows.
- 🛡️ **Privacy-first** — No cookies, no PII, no third-party data sharing. GDPR/CCPA friendly.
- 🪵 **Optional debug logging** — Enable verbose logs during development with a single flag.
- ⚠️ **Error monitoring** — Optional `onError` callback for production health checks.
- 🌐 **Configurable User-Agent** — Override the default browser UA string if needed.

## Getting Started

### Installation

Add `umami_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  umami_flutter: ^0.1.2
```

Or install via Git:

```yaml
dependencies:
  umami_flutter:
    git:
      url: https://github.com/hamzache497/flutter_umami.git
```

Then run:

```bash
flutter pub get
```

### Prerequisites

You need a running [Umami](https://umami.is) instance. You can:

- **Self-host** using Docker, Vercel, Netlify, or Railway ([setup guide](https://umami.is/docs/install))
- Use **Umami Cloud** at [cloud.umami.is](https://cloud.umami.is)

### Platform Setup

#### Android

No additional setup required. The package uses `android_id` and `EncryptedSharedPreferences` internally.

#### iOS / macOS

Keychain access is used for persistent device IDs. No extra entitlements are needed beyond the defaults.

## Usage

### 1. Initialize at app startup

Call `init()` once, typically in your `main()` or a splash screen. It returns immediately and never blocks.

```dart
import 'package:umami_flutter/umami_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  UmamiAnalytics.init(
    websiteId: 'your-website-id',
    serverUrl: 'https://your-umami.example.com',
    hostname: 'myapp',
    enableLogging: true, // optional, prints debug logs
    onError: (e) => debugPrint('Analytics error: $e'), // optional
  );

  runApp(MyApp());
}
```

### 2. Track screen views

```dart
UmamiAnalytics.trackScreen('HomeScreen');
```

### 3. Track custom events

```dart
UmamiAnalytics.trackEvent('purchase', data: {'plan': 'pro', 'price': 9.99});
```

> **Note:** Both `trackScreen` and `trackEvent` are safe to call _before_ `init()` finishes — events are queued automatically and sent once the client is ready.

## API Reference

| Method                                                     | Description                                                                                 |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `UmamiAnalytics.init(...)`                                 | Starts background device-info collection and prepares the HTTP client. Returns immediately. |
| `UmamiAnalytics.trackScreen(String screenName)`            | Sends a page-view event for the given screen name.                                          |
| `UmamiAnalytics.trackEvent(String eventName, {Map? data})` | Sends a custom event with an optional data payload.                                         |
| `UmamiAnalytics.reset()`                                   | Resets internal state, allowing `init()` to be called again. Primarily for testing.         |
| `UmamiAnalytics.isInitialized`                             | Whether `init()` has been called and hasn't failed.                                         |
| `DeviceIdService.getId()`                                  | Returns the persistent device ID (also accessible independently).                           |

### `init()` Parameters

| Parameter       | Required | Description                                    |
| --------------- | -------- | ---------------------------------------------- |
| `websiteId`     | ✅       | Website ID from your Umami dashboard.          |
| `serverUrl`     | ✅       | Base URL of your Umami instance.               |
| `hostname`      | ✅       | Logical hostname for this app.                 |
| `enableLogging` | ❌       | Print debug logs to console. Default: `false`. |
| `onError`       | ❌       | Callback invoked on init or send failures.     |
| `userAgent`     | ❌       | Custom User-Agent string override.             |

> **Supported platforms:** Android, iOS, macOS, Windows. Flutter Web is **not** supported (the package uses `dart:io`).

## Architecture

```
umami_flutter.dart          ← Public barrel export
└─ src/
   ├─ umami_analytics.dart  ← Static API (init, trackScreen, trackEvent)
   ├─ umami_client.dart     ← HTTP client for Umami /api/send endpoint
   ├─ device_info.dart      ← Collects device ID, locale, screen resolution
   └─ device_id_service.dart← Persistent device ID (Keychain / SecureStorage)
```

## Dependencies

| Package                                                                     | Purpose                                  |
| --------------------------------------------------------------------------- | ---------------------------------------- |
| [`http`](https://pub.dev/packages/http)                                     | HTTP requests to the Umami server        |
| [`device_info_plus`](https://pub.dev/packages/device_info_plus)             | Platform-specific device identifiers     |
| [`android_id`](https://pub.dev/packages/android_id)                         | Android device ID                        |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Persistent secure storage for device IDs |
| [`uuid`](https://pub.dev/packages/uuid)                                     | UUID v4 fallback for device IDs          |

## Related

- [Umami](https://umami.is) — Open-source, privacy-focused web analytics
- [Umami API Docs](https://umami.is/docs/api) — Sending events and API reference
- [Flutter Analytics Packages](https://pub.dev/packages?q=analytics) — Other analytics options on pub.dev

## Contributing

Contributions are welcome! Whether it's a bug fix, new feature, documentation improvement, or just a suggestion — feel free to get involved.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

If you find a bug or have a feature request, please [open an issue](https://github.com/hamzache497/flutter_umami/issues).

## License

MIT License — see [LICENSE](LICENSE) for details.
