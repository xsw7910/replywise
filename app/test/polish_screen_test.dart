import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/data/polish_repository.dart';
import 'package:replywise/features/polish/domain/polish_models.dart';
import 'package:replywise/features/polish/polish_screen.dart';

class _Storage extends TokenStorage {
  _Storage() : super(const FlutterSecureStorage());
}

class _DummyClient extends ApiClient {
  _DummyClient()
    : super(
        rawDio: Dio(),
        tokenStorage: _Storage(),
        recoverUnauthorized: () async => false,
      );
}

class _RecordingPolishRepository extends PolishRepository {
  _RecordingPolishRepository() : super(_DummyClient());

  PolishRequest? lastRequest;

  @override
  Future<PolishResult> polish(PolishRequest request) {
    lastRequest = request;
    return Completer<PolishResult>().future;
  }
}

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 6200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<_RecordingPolishRepository> _pumpPolish(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = _RecordingPolishRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        guidanceLibraryRepositoryProvider.overrideWith(
          (ref) =>
              GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
        ),
        polishRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: const MaterialApp(home: PolishScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _enterDraft(WidgetTester tester) =>
    tester.enterText(find.byType(TextField).first, 'Please review my draft.');

void main() {
  testWidgets('Polish shows Guidance and More options cards', (tester) async {
    _useTallView(tester);
    await _pumpPolish(tester);

    expect(find.text('Guidance'), findsOneWidget);
    expect(find.text('More options'), findsOneWidget);
  });

  testWidgets('selected guidance is sent in Polish request', (tester) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Be polite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Polish draft'));
    await tester.pump();

    expect(
      repository.lastRequest?.guidance,
      'Make the reply polite and respectful.',
    );
  });

  testWidgets('custom tone input is shown and sent in Polish request', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').at(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('polish-custom-tone-field')), findsOneWidget);
    await tester.enterText(
      _editableIn(const Key('polish-custom-tone-field')),
      ' warm but direct ',
    );
    await tester.tap(find.text('Polish draft'));
    await tester.pump();

    expect(repository.lastRequest?.tone, 'warm but direct');
  });

  testWidgets('custom audience input is shown and sent in Polish request', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').at(1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('polish-custom-audience-field')),
      findsOneWidget,
    );
    await tester.enterText(
      _editableIn(const Key('polish-custom-audience-field')),
      ' my customer ',
    );
    await tester.tap(find.text('Polish draft'));
    await tester.pump();

    expect(repository.lastRequest?.audience, 'my customer');
  });
}
