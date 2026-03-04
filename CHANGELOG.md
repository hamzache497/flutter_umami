## 0.1.0

- Initial release.
- Non-blocking `init()` with automatic device info collection.
- `trackScreen()` and `trackEvent()` — fire-and-forget, safe to call before init completes.
- Persistent device IDs via Keychain (iOS/macOS) and EncryptedSharedPreferences (Android).
- Platform-specific User-Agent for accurate OS detection in Umami.
- Optional `onError` callback for monitoring analytics health.
- Configurable User-Agent string override.
- Multi-platform support: Android, iOS, macOS, Windows.
