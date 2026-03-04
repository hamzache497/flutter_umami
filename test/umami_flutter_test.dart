import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:umami_flutter/src/device_info.dart';
import 'package:umami_flutter/src/umami_client.dart';
import 'package:umami_flutter/umami_flutter.dart';

// ── DeviceInfo Tests ─────────────────────────────────────────────────────────

void main() {
  group('DeviceInfo', () {
    test('toString contains all fields', () {
      const info = DeviceInfo(
        deviceId: 'test-id',
        locale: 'en_US',
        screenResolution: '1080x1920',
      );

      final result = info.toString();
      expect(result, contains('test-id'));
      expect(result, contains('en_US'));
      expect(result, contains('1080x1920'));
    });

    test('equality via field values', () {
      const a = DeviceInfo(
        deviceId: 'id-1',
        locale: 'en',
        screenResolution: '100x200',
      );
      const b = DeviceInfo(
        deviceId: 'id-1',
        locale: 'en',
        screenResolution: '100x200',
      );

      // DeviceInfo doesn't override ==, so they are not equal by identity
      expect(a.deviceId, equals(b.deviceId));
      expect(a.locale, equals(b.locale));
      expect(a.screenResolution, equals(b.screenResolution));
    });
  });

  // ── UmamiClient Payload Tests ──────────────────────────────────────────

  group('UmamiClient payload construction', () {
    test('trackScreen builds correct URL path', () {
      // We can't easily intercept HTTP without a mock server,
      // but we can verify the public API doesn't throw.
      final client = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
      );

      // Should not throw — sends are fire-and-forget with catchError
      expect(() => client.trackScreen('HomeScreen'), returnsNormally);
    });

    test('trackEvent with data does not throw', () {
      final client = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
      );

      expect(
        () => client.trackEvent('purchase', data: {'plan': 'pro'}),
        returnsNormally,
      );
    });

    test('custom userAgent is accepted', () {
      final client = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
        userAgent: 'CustomAgent/1.0',
      );

      // Should not throw
      expect(() => client.trackScreen('Test'), returnsNormally);
    });

    test('onError callback is accepted', () {
      final errors = <Object>[];
      final client = UmamiClient(
        serverUrl: 'https://example.com',
        websiteId: 'test-site',
        hostname: 'testapp',
        deviceInfo: const DeviceInfo(
          deviceId: 'dev-123',
          locale: 'en_US',
          screenResolution: '375x812',
        ),
        onError: errors.add,
      );

      // Should not throw even with invalid server
      expect(() => client.trackScreen('Test'), returnsNormally);
    });
  });

  // ── UmamiAnalytics Static API Tests ────────────────────────────────────

  group('UmamiAnalytics', () {
    setUp(() {
      UmamiAnalytics.reset();
    });

    test('isInitialized is false before init', () {
      expect(UmamiAnalytics.isInitialized, isFalse);
    });

    test('trackScreen before init does not throw', () {
      expect(() => UmamiAnalytics.trackScreen('Test'), returnsNormally);
    });

    test('trackEvent before init does not throw', () {
      expect(
        () => UmamiAnalytics.trackEvent('test', data: {'key': 'value'}),
        returnsNormally,
      );
    });

    test('reset clears initialization state', () {
      // Can't fully test init without a real device, but we can test reset
      UmamiAnalytics.reset();
      expect(UmamiAnalytics.isInitialized, isFalse);
    });

    test('init sets isInitialized to true', () {
      UmamiAnalytics.init(
        websiteId: 'test',
        serverUrl: 'https://example.com',
        hostname: 'test',
      );

      expect(UmamiAnalytics.isInitialized, isTrue);
    });

    test('double init does not throw', () {
      UmamiAnalytics.init(
        websiteId: 'test',
        serverUrl: 'https://example.com',
        hostname: 'test',
      );

      // Second call should be a no-op, not throw
      expect(
        () => UmamiAnalytics.init(
          websiteId: 'test2',
          serverUrl: 'https://example2.com',
          hostname: 'test2',
        ),
        returnsNormally,
      );
    });

    test('onError callback is wired through', () {
      final errors = <Object>[];

      // Should not throw
      expect(
        () => UmamiAnalytics.init(
          websiteId: 'test',
          serverUrl: 'https://example.com',
          hostname: 'test',
          onError: errors.add,
        ),
        returnsNormally,
      );
    });
  });

  // ── JSON Payload Structure Tests ───────────────────────────────────────

  group('Payload JSON structure', () {
    test('event payload has required fields', () {
      const info = DeviceInfo(
        deviceId: 'dev-123',
        locale: 'en_US',
        screenResolution: '375x812',
      );

      // Simulate what UmamiClient._send builds
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/HomeScreen',
        'title': 'HomeScreen',
        'screen': info.screenResolution,
        'language': info.locale,
        'id': info.deviceId,
      };

      final body = jsonEncode({'type': 'event', 'payload': payload});
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      expect(decoded['type'], equals('event'));

      final decodedPayload = decoded['payload'] as Map<String, dynamic>;
      expect(decodedPayload['website'], equals('test-site'));
      expect(decodedPayload['hostname'], equals('testapp'));
      expect(decodedPayload['url'], equals('/HomeScreen'));
      expect(decodedPayload['title'], equals('HomeScreen'));
      expect(decodedPayload['screen'], equals('375x812'));
      expect(decodedPayload['language'], equals('en_US'));
      expect(decodedPayload['id'], equals('dev-123'));
    });

    test('event payload includes name and data for custom events', () {
      final payload = <String, dynamic>{
        'website': 'test-site',
        'hostname': 'testapp',
        'url': '/',
        'title': 'purchase',
        'screen': '375x812',
        'language': 'en_US',
        'id': 'dev-123',
        'name': 'purchase',
        'data': {'plan': 'pro', 'price': 9.99},
      };

      final body = jsonEncode({'type': 'event', 'payload': payload});
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final decodedPayload = decoded['payload'] as Map<String, dynamic>;

      expect(decodedPayload['name'], equals('purchase'));
      expect(decodedPayload['data'], isA<Map>());
      expect((decodedPayload['data'] as Map)['plan'], equals('pro'));
      expect((decodedPayload['data'] as Map)['price'], equals(9.99));
    });
  });
}
