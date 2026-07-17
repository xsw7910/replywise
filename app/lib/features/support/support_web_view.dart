import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Everything the Support page needs to drive its loading/error UI, decoupled
/// from the concrete WebView so widget tests can inject a fake and never touch
/// a platform WebView.
class SupportWebViewRequest {
  const SupportWebViewRequest({
    required this.url,
    required this.onPageStarted,
    required this.onPageFinished,
    required this.onError,
    required this.onReady,
    required this.onExternalLink,
  });

  /// Initial URL to load.
  final Uri url;

  /// The main frame started loading.
  final VoidCallback onPageStarted;

  /// The main frame finished loading.
  final VoidCallback onPageFinished;

  /// The main frame failed to load.
  final VoidCallback onError;

  /// Hands the page a [SupportWebViewHandle] so it can reload / go back.
  final ValueChanged<SupportWebViewHandle> onReady;

  /// A navigation to an external (non-Tally) URL was requested; the page opens
  /// it with the app's URL launcher instead of loading it in the form.
  final Future<void> Function(Uri url) onExternalLink;
}

/// Commands the Support page can send to the live WebView.
class SupportWebViewHandle {
  const SupportWebViewHandle({
    required this.reload,
    required this.canGoBack,
    required this.goBack,
  });

  final Future<void> Function() reload;
  final Future<bool> Function() canGoBack;
  final Future<void> Function() goBack;
}

/// Builds the widget that renders the support form.
typedef SupportWebViewBuilder = Widget Function(SupportWebViewRequest request);

/// Whether [uri] belongs to Tally (the form host or a required Tally resource).
/// Everything else is treated as an external link.
bool isTallyUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  return host == 'tally.so' || host.endsWith('.tally.so');
}

/// Real implementation backed by `webview_flutter`. JavaScript is enabled
/// (Tally requires it); external links are handed back to the page; only
/// main-frame errors mark the form as failed.
Widget buildPlatformSupportWebView(SupportWebViewRequest request) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.white)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) => request.onPageStarted(),
        onPageFinished: (_) => request.onPageFinished(),
        onWebResourceError: (error) {
          // Ignore subresource failures (ads/fonts/etc.); only a failed main
          // frame means the form itself did not load.
          if (error.isForMainFrame ?? true) request.onError();
        },
        onNavigationRequest: (navigation) {
          final target = Uri.tryParse(navigation.url);
          if (target != null && !isTallyUrl(target)) {
            request.onExternalLink(target);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(request.url);

  request.onReady(
    SupportWebViewHandle(
      reload: controller.reload,
      canGoBack: controller.canGoBack,
      goBack: controller.goBack,
    ),
  );

  return WebViewWidget(controller: controller);
}

/// The Support page's WebView builder. Overridden in tests with a fake so no
/// platform WebView is required.
final supportWebViewBuilderProvider = Provider<SupportWebViewBuilder>(
  (ref) => buildPlatformSupportWebView,
);
