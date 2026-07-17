import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/constants/legal_urls.dart';

void main() {
  test('AppLinks contains the ReplyWise-specific legal URLs', () {
    expect(
      AppLinks.privacyPolicy,
      'https://xsw7910.github.io/novaaistudio-site/replywise-privacy.html',
    );
    expect(
      AppLinks.termsOfService,
      'https://xsw7910.github.io/novaaistudio-site/replywise-terms.html',
    );
  });

  test('retired legal URLs are no longer present in Flutter source', () {
    final appRoot = Directory.current;
    final sourceRoots = [
      Directory('${appRoot.path}${Platform.pathSeparator}lib'),
      Directory('${appRoot.path}${Platform.pathSeparator}test'),
    ];

    final retiredNeedles = <String>[
      'https://novaaistudio.ca/replywise/'
          'privacy',
      'https://novaaistudio.ca/replywise/'
          'terms',
      '/'
          'privacy.html',
      '/'
          'terms.html',
      'Rental Expense '
          'Keeper',
      'rental expense '
          'keeper',
    ];

    final offenders = <String>[];
    for (final root in sourceRoots) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final contents = entity.readAsStringSync();
        for (final needle in retiredNeedles) {
          if (contents.contains(needle)) {
            offenders.add('${entity.path}: $needle');
          }
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
