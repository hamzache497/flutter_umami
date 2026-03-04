import 'dart:ui';

import 'package:umami_flutter/src/device_id_service.dart';

/// Immutable snapshot of device metadata collected at init time.
class DeviceInfo {
  final String deviceId;
  final String locale;
  final String screenResolution;

  const DeviceInfo({
    required this.deviceId,
    required this.locale,
    required this.screenResolution,
  });

  @override
  String toString() =>
      'DeviceInfo(deviceId: $deviceId, locale: $locale, screen: $screenResolution)';
}

/// Gathers device ID, locale, and screen resolution in one async call.
///
/// Every field has a safe fallback so [gather] never throws.
class DeviceInfoService {
  DeviceInfoService._();

  static Future<DeviceInfo> gather() async {
    return DeviceInfo(
      deviceId: await _resolveDeviceId(),
      locale: _resolveLocale(),
      screenResolution: _resolveScreenResolution(),
    );
  }

  static Future<String> _resolveDeviceId() async {
    try {
      return await DeviceIdService.getId();
    } catch (_) {
      return 'unknown';
    }
  }

  static String _resolveLocale() {
    try {
      return PlatformDispatcher.instance.locale.toString();
    } catch (_) {
      return 'en';
    }
  }

  static String _resolveScreenResolution() {
    try {
      final displays = PlatformDispatcher.instance.displays;
      if (displays.isNotEmpty) {
        final display = displays.first;
        final size = display.size / display.devicePixelRatio;
        return '${size.width.toInt()}x${size.height.toInt()}';
      }
    } catch (_) {
      // Display API unavailable
    }
    return '0x0';
  }
}
