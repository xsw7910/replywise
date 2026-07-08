import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google Play listing for ReplyWise, opened by force/optional update prompts.
const String kReplyWisePlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.novaaistudio.replywise';

/// Opens the app's store listing. Returns false if no handler is available.
typedef StoreLauncher = Future<bool> Function();

Future<bool> _launchPlayStore() async {
  final uri = Uri.parse(kReplyWisePlayStoreUrl);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Indirection so update buttons can be exercised in tests without the
/// url_launcher platform channel.
final storeLauncherProvider = Provider<StoreLauncher>(
  (ref) => _launchPlayStore,
);
