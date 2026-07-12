import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../../../core/widgets/app_error_bottom_sheet.dart';
import '../../entitlement/presentation/out_of_credits_dialog.dart';
import '../application/app_status_controller.dart';
import '../domain/app_status.dart';
import 'app_status_launcher.dart';

/// Gates a Reply / Explain / Polish action against the cached app status.
///
/// Returns true when the request may proceed. When blocked it owns the
/// appropriate UI (maintenance / update-required / feature-unavailable bottom
/// sheet) and returns false.
Future<bool> ensureAppStatusAllows({
  required BuildContext context,
  required WidgetRef ref,
  required AppFeature feature,
}) async {
  final gate = await ref
      .read(appStatusControllerProvider.notifier)
      .guardFeature(feature);
  if (!context.mounted) return false;
  switch (gate) {
    case AppStatusGate.allowed:
      return true;
    case AppStatusGate.maintenance:
      await showAppMaintenanceDialog(context, ref, feature: feature);
      return false;
    case AppStatusGate.forceUpdate:
      await showForceUpdateDialog(context, ref, feature: feature);
      return false;
    case AppStatusGate.featureDisabled:
      await showFeatureUnavailableSheet(context, feature: feature);
      return false;
  }
}

/// Handles a Reply / Explain / Polish request that failed with a
/// network/server error: re-checks status, then shows the maintenance sheet
/// (if the backend reports maintenance) or the connection-problem sheet.
///
/// [onRetry] re-runs the original action from the connection sheet's
/// "Try again" button.
Future<void> handleAiRequestFailure({
  required BuildContext context,
  required WidgetRef ref,
  required AppFeature feature,
  VoidCallback? onRetry,
}) async {
  final outcome = await ref
      .read(appStatusControllerProvider.notifier)
      .refreshAfterRequestFailure();
  if (!context.mounted) return;
  switch (outcome) {
    case AppStatusPostError.maintenance:
      await showAppMaintenanceDialog(context, ref, feature: feature);
    case AppStatusPostError.serverUnavailable:
      await showServerUnavailableDialog(
        context,
        ref,
        feature: feature,
        onRetry: onRetry,
      );
  }
}

/// Whether an AI controller error code represents a network/server-reachability
/// failure (as opposed to a domain error like paywall or rate limiting).
bool isNetworkFailure(String? errorCode) => errorCode == 'NETWORK_ERROR';

/// Shows the empty-input error sheet. The action button only dismisses; no
/// request is made.
Future<void> showEmptyInputSheet(
  BuildContext context, {
  required AppFeature feature,
}) {
  final l10n = context.l10n;
  return showAppErrorBottomSheet<void>(
    context: context,
    feature: feature,
    sheetKey: const Key('empty-input-sheet'),
    icon: Icons.edit_note_rounded,
    title: l10n.errorEmptyInputTitle,
    message: l10n.errorEmptyInputMessage,
    primaryLabel: l10n.gotIt,
    primaryKey: const Key('empty-input-got-it'),
  );
}

/// Routes a failed AI request (non network-reachability) to the matching
/// error bottom sheet based on the controller's error code.
///
/// [message] is the already-user-friendly message from the controller and is
/// used for unmapped validation errors. [onRetry] re-runs the original action
/// for retryable errors.
Future<void> showAiErrorSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppFeature feature,
  required String? errorCode,
  required String message,
  VoidCallback? onRetry,
}) {
  final l10n = context.l10n;
  switch (errorCode) {
    case 'PAYWALL_REQUIRED':
      return showAppErrorBottomSheet<void>(
        context: context,
        feature: feature,
        sheetKey: const Key('credits-error-sheet'),
        icon: Icons.monetization_on_outlined,
        title: l10n.errorCreditsTitle,
        message: l10n.errorCreditsMessage,
        primaryLabel: l10n.getCredits,
        primaryKey: const Key('credits-error-get-credits'),
        onPrimary: () => GoRouter.of(context).push(AppRoutes.paywall),
        secondaryLabel: l10n.watchAd,
        secondaryKey: const Key('credits-error-watch-ad'),
        onSecondary: () => runWatchAdFlow(context: context, ref: ref),
      );
    case 'RATE_LIMITED':
      return showAppErrorBottomSheet<void>(
        context: context,
        feature: feature,
        sheetKey: const Key('rate-limited-sheet'),
        icon: Icons.hourglass_top_rounded,
        title: l10n.errorRateLimitedTitle,
        message: l10n.errorRateLimitedMessage,
        primaryLabel: l10n.gotIt,
        primaryKey: const Key('rate-limited-got-it'),
      );
    case 'MODEL_UNAVAILABLE':
    case 'MODEL_PARSE_ERROR':
    case 'IDEMPOTENCY_CONFLICT':
      return showAppErrorBottomSheet<void>(
        context: context,
        feature: feature,
        sheetKey: const Key('ai-busy-sheet'),
        icon: Icons.smart_toy_outlined,
        title: l10n.errorAiBusyTitle,
        message: l10n.errorAiBusyMessage,
        primaryLabel: l10n.tryAgain,
        primaryKey: const Key('ai-busy-try-again'),
        onPrimary: onRetry,
        technicalDetails: errorCode,
      );
    case null:
      // Local validation error (e.g. input too long): the controller message
      // is already specific and user-friendly; retrying would fail the same
      // way, so the button only dismisses.
      return showAppErrorBottomSheet<void>(
        context: context,
        feature: feature,
        sheetKey: const Key('unexpected-error-sheet'),
        icon: Icons.error_outline_rounded,
        title: l10n.errorUnexpectedTitle,
        message: message,
        primaryLabel: l10n.gotIt,
        primaryKey: const Key('unexpected-error-primary'),
      );
    default:
      return showAppErrorBottomSheet<void>(
        context: context,
        feature: feature,
        sheetKey: const Key('unexpected-error-sheet'),
        icon: Icons.error_outline_rounded,
        title: l10n.errorUnexpectedTitle,
        message: l10n.errorUnexpectedMessage,
        primaryLabel: l10n.tryAgain,
        primaryKey: const Key('unexpected-error-primary'),
        onPrimary: onRetry,
        technicalDetails: errorCode,
      );
  }
}

/// Feature disabled by remote config: dismissible informational sheet.
Future<void> showFeatureUnavailableSheet(
  BuildContext context, {
  required AppFeature feature,
}) {
  final l10n = context.l10n;
  return showAppErrorBottomSheet<void>(
    context: context,
    feature: feature,
    sheetKey: const Key('feature-unavailable-sheet'),
    icon: Icons.pause_circle_outline_rounded,
    title: l10n.appStatusFeatureUnavailableTitle,
    message: l10n.appStatusFeatureUnavailableMessage,
    primaryLabel: l10n.gotIt,
    primaryKey: const Key('feature-unavailable-got-it'),
  );
}

/// Blocking maintenance sheet: not dismissible; Retry re-checks app status
/// and closes the sheet once maintenance is over.
Future<void> showAppMaintenanceDialog(
  BuildContext context,
  WidgetRef ref, {
  required AppFeature feature,
}) => showModalBottomSheet<void>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _MaintenanceSheet(feature: feature),
);

/// Blocking force-update sheet: not dismissible; "Update now" opens the Play
/// Store listing, and Retry re-checks app status, dismissing only when the
/// update is no longer required.
Future<void> showForceUpdateDialog(
  BuildContext context,
  WidgetRef ref, {
  required AppFeature feature,
}) => showModalBottomSheet<void>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _ForceUpdateSheet(feature: feature),
);

/// Connection-problem sheet shown when the backend is unreachable and not in
/// maintenance. "Try again" re-runs [onRetry] (or refreshes app status).
Future<void> showServerUnavailableDialog(
  BuildContext context,
  WidgetRef ref, {
  required AppFeature feature,
  VoidCallback? onRetry,
}) {
  final l10n = context.l10n;
  return showAppErrorBottomSheet<void>(
    context: context,
    feature: feature,
    sheetKey: const Key('server-unavailable-dialog'),
    icon: Icons.cloud_off_rounded,
    title: l10n.errorConnectionTitle,
    message: l10n.errorConnectionMessage,
    primaryLabel: l10n.tryAgain,
    primaryKey: const Key('server-unavailable-retry'),
    onPrimary:
        onRetry ??
        () => ref.read(appStatusControllerProvider.notifier).refresh(),
  );
}

class _MaintenanceSheet extends ConsumerStatefulWidget {
  const _MaintenanceSheet({required this.feature});

  final AppFeature feature;

  @override
  ConsumerState<_MaintenanceSheet> createState() => _MaintenanceSheetState();
}

class _MaintenanceSheetState extends ConsumerState<_MaintenanceSheet> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(appStatusControllerProvider.notifier).refresh();
    if (!mounted) return;
    final stillDown =
        ref.read(appStatusControllerProvider).status?.maintenance ?? false;
    if (!stillDown) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(appStatusControllerProvider).status;
    final message = (status?.maintenanceMessage.isNotEmpty ?? false)
        ? status!.maintenanceMessage
        : l10n.appStatusServerUnavailableMessage;
    return AppErrorSheetContainer(
      sheetKey: const Key('maintenance-dialog'),
      child: AppErrorSheetBody(
        feature: widget.feature,
        icon: Icons.build_rounded,
        title: l10n.appStatusMaintenanceTitle,
        message: message,
        primaryLabel: l10n.retry,
        primaryKey: const Key('maintenance-retry'),
        primaryBusy: _retrying,
        onPrimary: _retrying ? null : _retry,
        showHandle: false,
      ),
    );
  }
}

class _ForceUpdateSheet extends ConsumerStatefulWidget {
  const _ForceUpdateSheet({required this.feature});

  final AppFeature feature;

  @override
  ConsumerState<_ForceUpdateSheet> createState() => _ForceUpdateSheetState();
}

class _ForceUpdateSheetState extends ConsumerState<_ForceUpdateSheet> {
  bool _retrying = false;

  /// Re-fetches the status; if forceUpdate is no longer required (flag turned
  /// off, or the supported floor dropped to this build), dismiss the sheet.
  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(appStatusControllerProvider.notifier).refresh();
    if (!mounted) return;
    final status = ref.read(appStatusControllerProvider).status;
    final stillRequired =
        status?.requiresForceUpdate(
          ref.read(currentAppVersionProvider),
          ref.read(currentAppBuildNumberProvider),
        ) ??
        false;
    if (!stillRequired) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(appStatusControllerProvider).status;
    final message = (status?.updateMessage.isNotEmpty ?? false)
        ? status!.updateMessage
        : l10n.appStatusFeatureUnavailableMessage;
    return AppErrorSheetContainer(
      sheetKey: const Key('force-update-dialog'),
      child: AppErrorSheetBody(
        feature: widget.feature,
        icon: Icons.system_update_rounded,
        title: l10n.appStatusUpdateRequiredTitle,
        message: message,
        primaryLabel: l10n.appStatusUpdateNow,
        primaryKey: const Key('force-update-now'),
        onPrimary: () => ref.read(storeLauncherProvider)(),
        secondaryLabel: l10n.retry,
        secondaryKey: const Key('force-update-retry'),
        secondaryBusy: _retrying,
        onSecondary: _retrying ? null : _retry,
        showHandle: false,
      ),
    );
  }
}
