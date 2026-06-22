import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/app.dart';
import 'package:replywise/features/auth/data/auth_repository.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/paywall/paywall_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';

// ── Auth fakes ─────────────────────────────────────────────────────────────
// Overriding the underlying providers keeps tests network-free without
// needing access to the private generated base class.

class _FakeStorage extends TokenStorage {
  _FakeStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getAppUserId() async => 'test-user-id';
  @override
  Future<String?> getDeviceId() async => 'test-device-id';
  @override
  Future<String?> getAccessToken() async => 'fake.access.token';
  @override
  Future<String?> getRefreshToken() async => 'fake.refresh.token';
  @override
  Future<void> saveAppUserId(String id) async {}
  @override
  Future<void> saveDeviceId(String id) async {}
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
}

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(Dio());

  @override
  Future<MeData> me({required String accessToken}) async =>
      const MeData(userId: 1, appUserId: 'test-user-id');
}

List<Override> get _authOverrides => [
  tokenStorageProvider.overrideWith((ref) => _FakeStorage()),
  authRepositoryProvider.overrideWith((ref) => _FakeAuthRepo()),
];

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  testWidgets('app exposes Reply, Polish, and Settings navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _authOverrides, child: const ReplyWiseApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsAtLeastNWidgets(1));
    expect(find.text('Polish'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Turn your intent into natural English'), findsOneWidget);

    await tester.tap(find.text('Polish'));
    await tester.pumpAndSettle();

    expect(find.text('Make your English sound natural'), findsOneWidget);
  });

  testWidgets('guidance chip fills the Reply guidance field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReplyScreen())),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Be polite'));
    await tester.pump();

    final guidanceField = find.descendant(
      of: find.byKey(const Key('reply-guidance-field')),
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(guidanceField);
    expect(field.controller?.text, 'Be polite');
  });

  testWidgets('paywall clearly remains a static two-path preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Start 3-day Free Trial'), findsOneWidget);
    expect(find.text('Buy Credits'), findsOneWidget);
    expect(find.textContaining('static preview'), findsOneWidget);

    await tester.tap(find.text('Start 3-day Free Trial'));
    await tester.pump();

    expect(
      find.text('Purchases are not available in this preview.'),
      findsOneWidget,
    );
  });
}
