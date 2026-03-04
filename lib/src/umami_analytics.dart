import 'dart:async';

import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';

/// Lightweight Umami analytics for Flutter.
///
/// Provides a simple static API for integrating
/// [Umami](https://umami.is) analytics into any Flutter app.
///
/// **Initialization** is non-blocking — [init] returns immediately while
/// device-info collection happens in the background. Events tracked before
/// init completes are automatically queued and flushed once the client is
/// ready.
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

  static Completer<UmamiClient>? _ready;
  static void Function(String)? _log;
  static void Function(Object error)? _onError;

  /// Whether [init] has been called and has not yet failed.
  static bool get isInitialized => _ready != null;

  /// Kicks off device-info collection in the background.
  ///
  /// Returns immediately — never blocks the caller. Events tracked before
  /// init completes are automatically queued and flushed once ready.
  ///
  /// Can be called again after a previous failure to retry initialization.
  /// Calling [init] while a previous init is already successfully completed
  /// is a no-op (a warning is logged if logging is enabled).
  ///
  /// Parameters:
  /// - [websiteId]: The website ID from your Umami dashboard.
  /// - [serverUrl]: The base URL of your Umami server
  ///   (e.g. `https://analytics.example.com`).
  /// - [hostname]: A logical hostname for this app (e.g. `myapp`).
  /// - [enableLogging]: If `true`, prints debug messages to the console.
  ///   Defaults to `false`.
  /// - [onError]: Optional callback invoked when init or event sending fails.
  ///   Useful for monitoring analytics health in production.
  /// - [userAgent]: Optional custom User-Agent string. If omitted, a
  ///   platform-appropriate browser User-Agent is used so Umami can
  ///   recognise the OS.
  static void init({
    required String websiteId,
    required String serverUrl,
    required String hostname,
    bool enableLogging = false,
    void Function(Object error)? onError,
    String? userAgent,
  }) {
    // Guard: already initialised successfully — skip.
    if (_ready != null && _ready!.isCompleted) {
      if (enableLogging) {
        // ignore: avoid_print
        print('[UmamiFlutter] Already initialized — ignoring duplicate init()');
      }
      return;
    }

    _onError = onError;

    if (enableLogging) {
      _log = (msg) => print(msg); // ignore: avoid_print
    } else {
      _log = null;
    }

    // Create a fresh completer (handles both first-init and retry-after-failure).
    _ready = Completer<UmamiClient>();

    _initAsync(
      websiteId: websiteId,
      serverUrl: serverUrl,
      hostname: hostname,
      userAgent: userAgent,
    );
  }

  static Future<void> _initAsync({
    required String websiteId,
    required String serverUrl,
    required String hostname,
    String? userAgent,
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
        onError: _onError,
        userAgent: userAgent,
      );

      _ready!.complete(client);

      _log?.call(
        '[UmamiFlutter] Ready in '
        '${DateTime.now().difference(start).inMilliseconds}ms '
        '| site=$websiteId | $deviceInfo',
      );
    } catch (e) {
      _log?.call('[UmamiFlutter] Init failed: $e');
      _onError?.call(e);
      // Reset so init() can be retried.
      _ready = null;
    }
  }

  /// Tracks a screen (page) view.
  ///
  /// [screenName] is sent as both the page URL path and title in Umami.
  ///
  /// Safe to call before [init] completes — the event is queued automatically.
  /// If [init] has not been called at all, the event is silently dropped.
  static void trackScreen(String screenName) {
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.trackScreen(screenName))
        .catchError((_) {}); // best-effort
  }

  /// Tracks a custom event with an optional [data] payload.
  ///
  /// [eventName] appears as the event name in the Umami dashboard.
  /// [data] is an arbitrary key-value map attached to the event.
  ///
  /// Safe to call before [init] completes — the event is queued automatically.
  /// If [init] has not been called at all, the event is silently dropped.
  static void trackEvent(String eventName, {Map<String, dynamic>? data}) {
    final completer = _ready;
    if (completer == null) return;
    completer.future
        .then((c) => c.trackEvent(eventName, data: data))
        .catchError((_) {}); // best-effort
  }

  /// Resets the analytics client, allowing [init] to be called again.
  ///
  /// This is primarily useful for testing. In production, prefer letting
  /// [init] handle retries automatically.
  static void reset() {
    _ready = null;
    _log = null;
    _onError = null;
  }
}
