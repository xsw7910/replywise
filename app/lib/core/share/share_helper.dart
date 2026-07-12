import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../localization/localization_extensions.dart';
import '../theme/app_feature_theme.dart';
import '../widgets/app_error_bottom_sheet.dart';

/// Opens the platform share sheet for [text]. Indirection so widget tests can
/// record calls without the share_plus platform channel (same pattern as
/// `storeLauncherProvider`).
typedef GeneratedTextSharer =
    Future<void> Function(String text, {String? subject});

Future<void> _shareWithPlatformSheet(String text, {String? subject}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

final generatedTextSharerProvider = Provider<GeneratedTextSharer>(
  (ref) => _shareWithPlatformSheet,
);

/// Shares generated result text via the platform share sheet.
///
/// Empty/whitespace-only text is never shared. A sharing failure is reported
/// with the existing error bottom sheet; it never crashes the page.
Future<void> shareGeneratedText(
  BuildContext context,
  WidgetRef ref,
  String text, {
  required AppFeature feature,
  String? subject,
}) async {
  final cleaned = text.trim();
  if (cleaned.isEmpty) return;
  try {
    await ref.read(generatedTextSharerProvider)(cleaned, subject: subject);
  } catch (_) {
    if (!context.mounted) return;
    final l10n = context.l10n;
    await showAppErrorBottomSheet<void>(
      context: context,
      feature: feature,
      sheetKey: const Key('share-failed-sheet'),
      icon: Icons.ios_share_outlined,
      title: l10n.errorUnexpectedTitle,
      message: l10n.errorUnexpectedMessage,
      primaryLabel: l10n.gotIt,
      primaryKey: const Key('share-failed-got-it'),
    );
  }
}
