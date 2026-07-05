import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/features/recent/data/recent_repository.dart';
import 'package:replywise/features/recent/domain/recent_item.dart';

const _key = 'replywise_recent_items_v1';

RecentItem _item(String id, {RecentType type = RecentType.reply}) => RecentItem(
  id: id,
  type: type,
  title: 'Title $id',
  inputText: 'input $id',
  outputText: 'output $id',
  createdAt: DateTime(2026, 7, 4, 14, 30),
);

Future<RecentRepository> _repo([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return RecentRepository(await SharedPreferences.getInstance());
}

void main() {
  group('buildRecentTitle', () {
    test('trims and collapses whitespace', () {
      expect(
        buildRecentTitle(RecentType.reply, '  Hi   John  \n hello '),
        'Reply to: Hi John hello',
      );
    });

    test('truncates long input to 36 chars with an ellipsis', () {
      final title = buildRecentTitle(RecentType.polish, 'a' * 50);
      expect(title, 'Polish: ${'a' * 36}...');
    });

    test('handles empty / whitespace-only input', () {
      expect(buildRecentTitle(RecentType.explain, '   '), 'Explain:');
      expect(buildRecentTitle(RecentType.reply, ''), 'Reply to:');
    });

    test('matches the documented example', () {
      final title = buildRecentTitle(
        RecentType.reply,
        'Hi John, sorry I missed your call yesterday...',
      );
      expect(title.startsWith('Reply to: Hi John, sorry I missed your'), isTrue);
      expect(title.endsWith('...'), isTrue);
    });
  });

  group('RecentItem JSON', () {
    test('round-trips every field', () {
      final item = RecentItem(
        id: 'x',
        type: RecentType.polish,
        title: 'Polish: hi',
        inputText: 'hi',
        outputText: 'HI',
        createdAt: DateTime.utc(2026, 7, 4, 14, 30),
        guidance: 'be nice',
        tone: 'Friendly',
        channel: 'Email',
        length: 'Short',
      );
      final decoded = RecentItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.id, 'x');
      expect(decoded.type, RecentType.polish);
      expect(decoded.title, 'Polish: hi');
      expect(decoded.inputText, 'hi');
      expect(decoded.outputText, 'HI');
      expect(decoded.createdAt.toUtc(), DateTime.utc(2026, 7, 4, 14, 30));
      expect(decoded.guidance, 'be nice');
      expect(decoded.tone, 'Friendly');
      expect(decoded.channel, 'Email');
      expect(decoded.length, 'Short');
    });

    test('omits null optional fields from JSON', () {
      expect(_item('a').toJson().containsKey('guidance'), isFalse);
    });

    test('create() generates an id, title, and timestamp', () {
      final item = RecentItem.create(
        type: RecentType.reply,
        inputText: 'Hello there friend',
        outputText: 'Hi!',
      );
      expect(item.id, isNotEmpty);
      expect(item.title, 'Reply to: Hello there friend');
      expect(item.type, RecentType.reply);
    });
  });

  group('RecentRepository', () {
    test('stores newest first', () async {
      final repo = await _repo();
      await repo.add(_item('a'));
      await repo.add(_item('b'));
      expect((await repo.getAll()).map((e) => e.id).toList(), ['b', 'a']);
    });

    test('deduplicates by id and moves it to the front', () async {
      final repo = await _repo();
      await repo.add(_item('a'));
      await repo.add(_item('b'));
      await repo.add(_item('a'));
      expect((await repo.getAll()).map((e) => e.id).toList(), ['a', 'b']);
    });

    test('deduplicates by type + input, updating output and moving to top',
        () async {
      final repo = await _repo();
      await repo.add(
        RecentItem(
          id: 'a',
          type: RecentType.reply,
          title: 'Reply to: hi',
          inputText: 'same input',
          outputText: 'first',
          createdAt: DateTime(2026, 7, 4, 10),
        ),
      );
      await repo.add(_item('b')); // different input — stays
      // Regenerate of the same input: new id and new output.
      await repo.add(
        RecentItem(
          id: 'c',
          type: RecentType.reply,
          title: 'Reply to: hi',
          inputText: 'same input',
          outputText: 'second',
          createdAt: DateTime(2026, 7, 4, 11),
        ),
      );

      final all = await repo.getAll();
      expect(all.length, 2, reason: 'the regenerate must not add a duplicate');
      expect(all.first.id, 'c');
      expect(all.first.outputText, 'second');
      expect(all.where((e) => e.inputText == 'same input').length, 1);
    });

    test('does not deduplicate the same input across different types', () async {
      final repo = await _repo();
      await repo.add(
        RecentItem(
          id: 'a',
          type: RecentType.reply,
          title: 't',
          inputText: 'shared',
          outputText: 'o',
          createdAt: DateTime(2026),
        ),
      );
      await repo.add(
        RecentItem(
          id: 'b',
          type: RecentType.polish,
          title: 't',
          inputText: 'shared',
          outputText: 'o',
          createdAt: DateTime(2026),
        ),
      );
      expect((await repo.getAll()).length, 2);
    });

    test('skips a malformed record but keeps the valid ones', () async {
      final good = _item('a').toJson();
      final bad = {
        'id': 'b',
        'type': 'not_a_real_type', // byName throws → this record is skipped
        'title': 't',
        'createdAt': '2026-07-04T10:00:00.000',
      };
      final repo = await _repo({_key: jsonEncode([bad, good])});
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.single.id, 'a');
    });

    test('getLatest limits the result', () async {
      final repo = await _repo();
      for (final id in ['a', 'b', 'c']) {
        await repo.add(_item(id));
      }
      expect(
        (await repo.getLatest(limit: 2)).map((e) => e.id).toList(),
        ['c', 'b'],
      );
    });

    test('caps stored items at 50 (keeping the newest)', () async {
      final repo = await _repo();
      for (var i = 0; i < 55; i++) {
        await repo.add(_item('id$i'));
      }
      final all = await repo.getAll();
      expect(all.length, 50);
      expect(all.first.id, 'id54');
      expect(all.last.id, 'id5');
    });

    test('delete removes a single item', () async {
      final repo = await _repo();
      await repo.add(_item('a'));
      await repo.add(_item('b'));
      await repo.delete('a');
      expect((await repo.getAll()).map((e) => e.id).toList(), ['b']);
    });

    test('clear empties the store', () async {
      final repo = await _repo();
      await repo.add(_item('a'));
      await repo.clear();
      expect(await repo.getAll(), isEmpty);
    });

    test('corrupted JSON returns an empty list, no crash', () async {
      final repo = await _repo({_key: 'not-valid-json'});
      expect(await repo.getAll(), isEmpty);
    });

    test('non-list JSON returns an empty list', () async {
      final repo = await _repo({_key: '{"unexpected":"shape"}'});
      expect(await repo.getAll(), isEmpty);
    });

    test('persisted data survives a new repository instance (restart)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await RecentRepository(prefs).add(_item('a'));
      expect((await RecentRepository(prefs).getAll()).single.id, 'a');
    });
  });
}
