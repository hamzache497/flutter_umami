import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Resolves and persists a stable device ID across app reinstalls.
///
/// Uses platform-specific identifiers where available, with a UUID fallback.
/// The ID is persisted in secure storage (Keychain on iOS, EncryptedSharedPrefs
/// on Android) so it survives reinstalls.
class DeviceIdService {
  static const _storageKey = 'umami_persistent_device_id';
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Uuid _uuid = Uuid();

  /// In-memory cache to avoid repeated I/O.
  static String? _cachedId;

  DeviceIdService._();

  /// Returns a persistent device ID. Safe to call from any platform.
  static Future<String> getId() async {
    if (_cachedId != null) return _cachedId!;

    // 1. Check secure storage
    try {
      final existing = await _storage.read(key: _storageKey);
      if (existing != null) {
        _cachedId = existing;
        return existing;
      }
    } catch (_) {
      // Secure storage unavailable — fall through
    }

    // 2. Platform-specific identifier, or UUID fallback
    final id = await _getOSIdentifier() ?? _uuid.v4();

    // 3. Persist for future reads
    try {
      await _storage.write(key: _storageKey, value: id);
    } catch (_) {
      // Best effort
    }

    _cachedId = id;
    return id;
  }

  static Future<String?> _getOSIdentifier() async {
    try {
      if (Platform.isAndroid) {
        const androidId = AndroidId();
        return await androidId.getId();
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        return ios.identifierForVendor;
      } else if (Platform.isMacOS) {
        final mac = await _deviceInfo.macOsInfo;
        return mac.systemGUID;
      } else if (Platform.isWindows) {
        final win = await _deviceInfo.windowsInfo;
        return win.deviceId;
      }
    } catch (_) {
      // Platform plugin not available
    }
    return null;
  }
}
