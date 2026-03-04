/// Lightweight Umami analytics for Flutter.
///
/// Provides non-blocking initialization with automatic device info collection
/// and fire-and-forget event tracking.
///
/// ```dart
/// import 'package:umami_flutter/umami_flutter.dart';
///
/// // At startup (returns immediately):
/// UmamiAnalytics.init(
///   websiteId: 'your-website-id',
///   serverUrl: 'https://your-umami.example.com',
///   hostname: 'myapp',
/// );
///
/// // Track at any time:
/// UmamiAnalytics.trackScreen('HomeScreen');
/// UmamiAnalytics.trackEvent('purchase', data: {'plan': 'pro'});
/// ```
library umami_flutter;

export 'src/umami_analytics.dart';
