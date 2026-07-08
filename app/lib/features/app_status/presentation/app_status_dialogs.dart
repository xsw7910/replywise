import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../application/app_status_controller.dart';
import '../domain/app_status.dart';
import 'app_status_launcher.dart';

const Color _dialogBackground = Color(0xFFFFFCF7);

/// Gates a Reply / Polish / Explain action against the cached app status.
///
/// Returns true when the request may proceed. When blocked it owns the
/// appropriate UI (maintenance / update-required dialog or a disabled-feature
/// message) and returns false.
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
      await showAppMaintenanceDialog(context, ref);
      return false;
    case AppStatusGate.forceUpdate:
      await showForceUpdateDialog(context, ref);
      return false;
    case AppStatusGate.featureDisabled:
      showFeatureUnavailableMessage(context);
      return false;
  }
}

/// Handles a Reply / Polish / Explain request that failed with a
/// network/server error: re-checks status, then shows the maintenance dialog
/// (if the backend reports maintenance) or the local server-unavailable
/// fallback otherwise.
Future<void> handleAiRequestFailure({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final outcome = await ref
      .read(appStatusControllerProvider.notifier)
      .refreshAfterRequestFailure();
  if (!context.mounted) return;
  switch (outcome) {
    case AppStatusPostError.maintenance:
      await showAppMaintenanceDialog(context, ref);
    case AppStatusPostError.serverUnavailable:
      await showServerUnavailableDialog(context, ref);
  }
}

/// Whether an AI controller error code represents a network/server-reachability
/// failure (as opposed to a domain error like paywall or rate limiting).
bool isNetworkFailure(String? errorCode) => errorCode == 'NETWORK_ERROR';

void showFeatureUnavailableMessage(BuildContext context) {
  final l10n = context.l10n;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const Key('feature-unavailable-snackbar'),
        content: Text(l10n.appStatusFeatureUnavailableMessage),
      ),
    );
}

Future<void> showAppMaintenanceDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MaintenanceDialog(),
    );

Future<void> showForceUpdateDialog(BuildContext context, WidgetRef ref) {
  final status = ref.read(appStatusControllerProvider).status;
  final l10n = context.l10n;
  final message = (status?.updateMessage.isNotEmpty ?? false)
      ? status!.updateMessage
      : l10n.appStatusFeatureUnavailableMessage;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _AppStatusDialog(
      dialogKey: const Key('force-update-dialog'),
      icon: Icons.system_update_rounded,
      title: l10n.appStatusUpdateRequiredTitle,
      message: message,
      primaryLabel: l10n.appStatusUpdateNow,
      primaryKey: const Key('force-update-now'),
      onPrimary: () => ref.read(storeLauncherProvider)(),
    ),
  );
}

Future<void> showServerUnavailableDialog(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AppStatusDialog(
      dialogKey: const Key('server-unavailable-dialog'),
      icon: Icons.cloud_off_rounded,
      title: l10n.connectionFailed,
      message: l10n.appStatusServerUnavailableMessage,
      primaryLabel: l10n.retry,
      primaryKey: const Key('server-unavailable-retry'),
      onPrimary: () {
        Navigator.of(dialogContext).pop();
        ref.read(appStatusControllerProvider.notifier).refresh();
      },
    ),
  );
}

class _MaintenanceDialog extends ConsumerStatefulWidget {
  const _MaintenanceDialog();

  @override
  ConsumerState<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends ConsumerState<_MaintenanceDialog> {
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
    return _AppStatusDialog(
      dialogKey: const Key('maintenance-dialog'),
      icon: Icons.build_rounded,
      title: l10n.appStatusMaintenanceTitle,
      message: message,
      primaryLabel: l10n.retry,
      primaryKey: const Key('maintenance-retry'),
      primaryBusy: _retrying,
      onPrimary: _retrying ? null : _retry,
    );
  }
}

/// Shared rounded dialog scaffold for the app-status prompts. A single primary
/// action mirrors the OutOfCreditsDialog visual language.
class _AppStatusDialog extends StatelessWidget {
  const _AppStatusDialog({
    required this.dialogKey,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryKey,
    required this.onPrimary,
    this.primaryBusy = false,
  });

  final Key dialogKey;
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final Key primaryKey;
  final VoidCallback? onPrimary;
  final bool primaryBusy;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: dialogKey,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: _dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 44, color: AppColors.textPrimary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: primaryKey,
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF38AD49),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: primaryBusy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(primaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
