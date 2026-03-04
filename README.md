# umami_flutter

A lightweight Flutter package for [Umami](https://umami.is) analytics with **non-blocking initialization** and **automatic device info collection**.

[![Dart](https://img.shields.io/badge/Dart-%5E3.7.2-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-02569B)](https://flutter.dev)

## Features

- 🚀 **Non-blocking init** — `init()` returns immediately; events tracked before initialization completes are automatically queued and flushed.
- 📱 **Automatic device info** — Collects device ID, locale, and screen resolution out of the box.
- 🔒 **Persistent device IDs** — Uses platform-specific identifiers (Android ID, `identifierForVendor`, etc.) persisted in secure storage (Keychain / EncryptedSharedPreferences) to survive app reinstalls.
- 🔥 **Fire-and-forget tracking** — `trackScreen` and `trackEvent` never block the UI thread.
- 🖥️ **Multi-platform** — Supports Android, iOS, macOS, and Windows.
- 🪵 **Optional debug logging** — Enable verbose logs during development with a single flag.

## Getting Started

### Installation

Add `umami_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  umami_flutter:
    git:
      url: https://github.com/hamzache497/umami_flutter.git
```

Then run:

```bash
flutter pub get
```

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

## License

See [LICENSE](LICENSE) for details.
