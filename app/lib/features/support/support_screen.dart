import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/launch/external_url_launcher.dart';
import '../../core/router/app_router.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import 'support_url.dart';
import 'support_web_view.dart';

enum _LoadState { loading, loaded, error }

/// In-app Support page: renders the Tally support form in a WebView behind a
/// native ReplyWise header, with loading and error states. The WebView is
/// injected via [supportWebViewBuilderProvider] so it can be faked in tests.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  late final Uri _url;
  late final Widget _webView;
  SupportWebViewHandle? _handle;
  _LoadState _state = _LoadState.loading;

  @override
  void initState() {
    super.initState();
    // Built exactly once so rebuilds never recreate the controller (which would
    // reload the form and drop the user's input).
    _url = ref.read(supportFormUrlProvider);
    _webView = ref.read(supportWebViewBuilderProvider)(
      SupportWebViewRequest(
        url: _url,
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
        onError: _onError,
        onReady: (handle) => _handle = handle,
        onExternalLink: _openExternal,
      ),
    );
  }

  void _onPageStarted() {
    if (mounted) setState(() => _state = _LoadState.loading);
  }

  void _onPageFinished() {
    // A late main-frame error can arrive after finish; don't override it.
    if (mounted && _state != _LoadState.error) {
      setState(() => _state = _LoadState.loaded);
    }
  }

  void _onError() {
    if (mounted) setState(() => _state = _LoadState.error);
  }

  Future<void> _reload() async {
    setState(() => _state = _LoadState.loading);
    await _handle?.reload();
  }

  Future<void> _openExternal(Uri url) async {
    final opened = await ref.read(externalUrlLauncherProvider)(url);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenLink)));
  }

  Future<void> _openInBrowser() => _openExternal(_url);

  /// Android back / header back: step back through the form's history first,
  /// otherwise leave the page.
  ///
  /// The leave step uses a real [GoRouter] pop (not `maybePop`) so it is not
  /// re-intercepted by this page's [PopScope] — a `maybePop` here would fire
  /// [PopScope.onPopInvokedWithResult] again and trap the page instead of
  /// popping it.
  Future<void> _handleBack() async {
    final handle = _handle;
    if (handle != null && await handle.canGoBack()) {
      await handle.goBack();
      return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      // No route to pop (unexpected): fall back to the Settings page rather
      // than leaving the user stranded on the form.
      context.go(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AppPage(
        title: context.l10n.support,
        showBackButton: true,
        onBack: _handleBack,
        child: Column(
          children: [
            const _SensitiveInfoNotice(),
            Expanded(
              child: Stack(
                children: [
                  // Kept in the tree across states so the loaded form is not
                  // rebuilt when the loading overlay disappears.
                  Offstage(
                    offstage: _state == _LoadState.error,
                    child: _webView,
                  ),
                  if (_state == _LoadState.loading) const _LoadingOverlay(),
                  if (_state == _LoadState.error)
                    _ErrorView(
                      onTryAgain: _reload,
                      onOpenInBrowser: _openInBrowser,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent reminder shown above the form.
class _SensitiveInfoNotice extends StatelessWidget {
  const _SensitiveInfoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('support-sensitive-notice'),
      width: double.infinity,
      color: const Color(0xFFFFF7E6),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.guidanceDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.supportSensitiveInfoNotice,
              style: AppTextStyles.helper.copyWith(
                color: AppColors.guidanceDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('support-loading'),
      color: AppColors.backgroundBase,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(context.l10n.loadingSupportForm, style: AppTextStyles.helper),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onTryAgain, required this.onOpenInBrowser});

  final VoidCallback onTryAgain;
  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('support-error'),
      color: AppColors.backgroundBase,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.unableToLoadSupportForm,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.checkConnectionAndTryAgain,
            textAlign: TextAlign.center,
            style: AppTextStyles.helper,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('support-try-again'),
            onPressed: onTryAgain,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(context.l10n.tryAgain),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('support-open-browser'),
            onPressed: onOpenInBrowser,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(context.l10n.openInBrowser),
          ),
        ],
      ),
    );
  }
}
