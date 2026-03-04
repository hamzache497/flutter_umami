import 'dart:async';

import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';

/// Lightweight Umami analytics for Flutter.
///
/// ```dart
/// // At app startup (returns immediately, never blocks):
/// UmamiAnalytics.init(
///   websiteId: 'your-website-id',
///   serverUrl: 'https://your-umami.example.com',
///   hostname: 'myapp',
/// );
///
/// // Track events at any time — even before init finishes:
/// UmamiAnalytics.trackScreen('HomeScreen');
/// UmamiAnalytics.trackEvent('purchase', data: {'plan': 'pro'});
/// ```
class UmamiAnalytics {
  UmamiAnalytics._();

  static final Completer<UmamiClient> _ready = Completer();
  static void Function(String)? _log;

  /// Kicks off device-info collection in the background.
  ///
  /// Returns immediately — never blocks the caller. Events tracked before
  /// init completes are automatically queued and flushed once ready.
  ///
  /// Set [enableLogging] to `true` to print debug logs (disabled by default).
  static void init({
    required String websiteId,
    required String serverUrl,
    required String hostname,
    bool enableLogging = false,
  }) {
    if (enableLogging) {
      _log = (msg) => print(msg); // ignore: avoid_print
    }

    _initAsync(websiteId: websiteId, serverUrl: serverUrl, hostname: hostname);
  }

  static Future<void> _initAsync({
    required String websiteId,
    required String serverUrl,
    required String hostname,
  }) async {
    try {
      final start = DateTime.now();

      final deviceInfo = await DeviceInfoService.gather();

      final client = UmamiClient(
        serverUrl: serverUrl,
        websiteId: websiteId,
        hostname: hostname,
        deviceInfo: deviceInfo,
        log: _log,
      );

      _ready.complete(client);

      _log?.call(
        '[UmamiFlutter] Ready in '
        '${DateTime.now().difference(start).inMilliseconds}ms '
        '| site=$websiteId | $deviceInfo',
      );
    } catch (e) {
      _log?.call('[UmamiFlutter] Init failed: $e');
      _ready.completeError(e);
    }
  }

  /// Track a screen (page) view.
  ///
  /// Safe to call before [init] completes — the event is queued automatically.
  static void trackScreen(String screenName) {
    _ready.future
        .then((c) => c.trackScreen(screenName))
        .catchError((_) {}); // best-effort
  }

  /// Track a custom event with an optional data map.
  ///
  /// Safe to call before [init] completes — the event is queued automatically.
  static void trackEvent(String eventName, {Map<String, dynamic>? data}) {
    _ready.future
        .then((c) => c.trackEvent(eventName, data: data))
        .catchError((_) {}); // best-effort
  }
}
