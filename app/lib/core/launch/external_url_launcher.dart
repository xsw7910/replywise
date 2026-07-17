import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external [url] (browser / mail / etc.). Returns false when no
/// handler is available, so callers can surface the app's error UI instead of
/// throwing. Mirrors the indirection used by `storeLauncherProvider` and
/// `generatedTextSharerProvider` so widget tests can record calls without the
/// url_launcher platform channel.
typedef ExternalUrlLauncher = Future<bool> Function(Uri url);

Future<bool> _launchExternalUrl(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// The app's external-link opener. Reused wherever an external URL is launched
/// (e.g. the About page's Privacy Policy / Terms of Service rows).
final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>(
  (ref) => _launchExternalUrl,
);
