import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'token_storage.dart';
import 'platform_detector_stub.dart'
    if (dart.library.io) 'platform_detector_io.dart';

part 'device_identity.g.dart';

/// App-specific (non-secret) namespace mixed into the device hash. This is
/// not a security secret — it only keeps the hash distinct from other apps
/// that might hash the same Android ID.
const _kDeviceIdSalt = 'replywise-device-id-v1';

/// Must match `applicationId` in android/app/build.gradle.kts.
const _kAndroidPackageName = 'com.novaaistudio.replywise';

/// Thin seam over the `android_id` plugin so tests can substitute a fake
/// source instead of going through a platform channel.
abstract class AndroidIdSource {
  Future<String?> getId();
}

class _PluginAndroidIdSource implements AndroidIdSource {
  const _PluginAndroidIdSource();

  @override
  Future<String?> getId() => const AndroidId().getId();
}

/// Resolves a stable, privacy-preserving device identifier.
///
/// On Android this hashes `Settings.Secure.ANDROID_ID` (SHA-256, salted with
/// the package name and an app-specific constant) so the raw Android ID
/// never leaves the device. Android ID survives app uninstall/reinstall (it
/// only changes on factory reset, or if the app's signing key changes), so
/// this prevents the free-usage quota from resetting on reinstall — unlike
/// the old random UUID, which lived only in [TokenStorage] and was wiped on
/// uninstall. Other platforms — and Android when the ID is unavailable —
/// fall back to a UUID persisted in secure storage, matching prior behavior.
class DeviceIdentity {
  DeviceIdentity({AndroidIdSource? androidIdSource, bool Function()? isAndroid})
    : _androidIdSource = androidIdSource ?? const _PluginAndroidIdSource(),
      _isAndroid = isAndroid ?? _defaultIsAndroid;

  final AndroidIdSource _androidIdSource;
  final bool Function() _isAndroid;

  static bool _defaultIsAndroid() => !kIsWeb && isAndroidPlatform;

  static String _prefix(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);

  static void _debugLog(String message) {
    if (kDebugMode) debugPrint(message);
  }

  Future<String?> _stableAndroidHash() async {
    if (!_isAndroid()) {
      _debugLog('DeviceIdentity: not Android, using fallback');
      return null;
    }
    try {
      final id = await _androidIdSource.getId();
      if (id == null || id.isEmpty) {
        _debugLog('DeviceIdentity: Android ID empty, using fallback');
        return null;
      }
      final digest = sha256.convert(
        utf8.encode('$id$_kAndroidPackageName$_kDeviceIdSalt'),
      );
      final hash = digest.toString();
      _debugLog('DeviceIdentity path: android_id, prefix=${_prefix(hash)}');
      return hash;
    } catch (_) {
      // Plugin unavailable, missing platform implementation, or any other
      // failure — fall back to the install UUID below rather than crash.
      _debugLog('DeviceIdentity: Android ID unavailable, using fallback');
      return null;
    }
  }

  /// Returns the stable Android-derived hash when available, otherwise a
  /// UUID persisted in [storage] (minted once on first call).
  Future<String> resolve(TokenStorage storage) async {
    final stable = await _stableAndroidHash();
    if (stable != null) return stable;

    var fallback = await storage.getDeviceId();
    if (fallback == null) {
      fallback = const Uuid().v4();
      await storage.saveDeviceId(fallback);
    }
    _debugLog(
      'DeviceIdentity path: fallback_uuid, prefix=${_prefix(fallback)}',
    );
    return fallback;
  }
}

@Riverpod(keepAlive: true)
DeviceIdentity deviceIdentity(DeviceIdentityRef ref) => DeviceIdentity();
