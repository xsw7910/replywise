import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replywise/core/theme/app_theme.dart';

void main() {
  test('UI source contains no forbidden black color literals', () {
    const forbidden = [
      'Colors.black',
      'Color(0xFF000000)',
      'Color(0xDE000000)',
      'Color(0xDD000000)',
      'Color(0x8A000000)',
    ];
    final matches = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final pattern in forbidden) {
        if (source.contains(pattern)) {
          matches.add('${entity.path}: $pattern');
        }
      }
    }

    expect(matches, isEmpty);
  });

  test('every default Material text style has an explicit non-black color', () {
    final textTheme = AppTheme.light.textTheme;
    final styles = [
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
      textTheme.titleMedium,
      textTheme.titleSmall,
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.labelMedium,
      textTheme.labelSmall,
    ];
    final forbidden = {
      const Color(0xFF000000),
      const Color(0xDE000000),
      const Color(0xDD000000),
      const Color(0x8A000000),
    };

    for (final style in styles) {
      expect(style, isNotNull);
      expect(style!.color, isNotNull);
      expect(forbidden, isNot(contains(style.color)));
    }
  });

  test('app theme can interpolate with the Material default theme', () {
    expect(
      () => ThemeData.lerp(ThemeData.light(), AppTheme.light, 0.5),
      returnsNormally,
    );
  });
}
