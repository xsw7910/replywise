import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/features/auth/data/device_identity.dart';
import 'package:replywise/features/auth/data/token_storage.dart';

class _FakeAndroidIdSource implements AndroidIdSource {
  _FakeAndroidIdSource(this._id);

  final String? _id;

  @override
  Future<String?> getId() async => _id;
}

class _ThrowingAndroidIdSource implements AndroidIdSource {
  @override
  Future<String?> getId() => throw Exception('platform channel unavailable');
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage() : super(const FlutterSecureStorage());

  String? _deviceId;

  @override
  Future<String?> getDeviceId() async => _deviceId;

  @override
  Future<void> saveDeviceId(String id) async => _deviceId = id;
}

void main() {
  group('DeviceIdentity on Android', () {
    test('same Android ID source produces the same device hash', () async {
      final identity = DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource('AAAA-1111'),
        isAndroid: () => true,
      );

      final first = await identity.resolve(_MemoryTokenStorage());
      final second = await identity.resolve(_MemoryTokenStorage());

      expect(first, second);
      expect(first, hasLength(64)); // SHA-256 hex digest.
    });

    test('different Android ID source produces a different device hash', () async {
      final hashA = await DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource('AAAA-1111'),
        isAndroid: () => true,
      ).resolve(_MemoryTokenStorage());
      final hashB = await DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource('BBBB-2222'),
        isAndroid: () => true,
      ).resolve(_MemoryTokenStorage());

      expect(hashA, isNot(equals(hashB)));
    });

    test('never sends the raw Android ID — only its SHA-256 hash', () async {
      const rawId = 'super-secret-android-id';
      final hash = await DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource(rawId),
        isAndroid: () => true,
      ).resolve(_MemoryTokenStorage());

      expect(hash, isNot(contains(rawId)));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });

    test('survives "reinstall" — a fresh TokenStorage with no saved '
        'install UUID still resolves to the same hash', () async {
      final identity = DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource('STABLE-ANDROID-ID'),
        isAndroid: () => true,
      );

      final beforeReinstall = await identity.resolve(_MemoryTokenStorage());
      // Reinstall wipes secure storage — simulated with a brand-new instance.
      final afterReinstall = await identity.resolve(_MemoryTokenStorage());

      expect(afterReinstall, beforeReinstall);
    });

    test('empty Android ID falls back to a persisted install UUID', () async {
      final identity = DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource(''),
        isAndroid: () => true,
      );
      final storage = _MemoryTokenStorage();

      final first = await identity.resolve(storage);
      final second = await identity.resolve(storage);

      expect(first, second);
      expect(await storage.getDeviceId(), first);
    });

    test('plugin failure falls back to a persisted install UUID without '
        'throwing', () async {
      final identity = DeviceIdentity(
        androidIdSource: _ThrowingAndroidIdSource(),
        isAndroid: () => true,
      );
      final storage = _MemoryTokenStorage();

      final id = await identity.resolve(storage);

      expect(id, isNotEmpty);
      expect(await storage.getDeviceId(), id);
    });
  });

  group('DeviceIdentity on non-Android platforms', () {
    test('falls back to a persisted install UUID and keeps it stable', () async {
      final identity = DeviceIdentity(
        androidIdSource: _FakeAndroidIdSource('unused-on-this-platform'),
        isAndroid: () => false,
      );
      final storage = _MemoryTokenStorage();

      final first = await identity.resolve(storage);
      final second = await identity.resolve(storage);

      expect(first, second);
      expect(await storage.getDeviceId(), first);
    });
  });
}
