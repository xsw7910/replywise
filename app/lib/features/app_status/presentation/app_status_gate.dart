import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/app_status_controller.dart';
import 'app_status_launcher.dart';

/// Wraps the app (via `MaterialApp.router`'s `builder`) and enforces the
/// app-wide status states that must sit above every route:
///
/// * **Force update** — a full-screen, non-dismissible block. The app cannot be
///   used until the user updates.
/// * **Optional update** — a dismissible prompt that overlays the app without
///   blocking it ("Later" continues to the app).
///
/// Maintenance and disabled-feature handling live with the per-request gate
/// (`ensureAppStatusAllows`) so local, non-AI screens stay usable during a
/// backend outage. This widget renders nothing extra in the normal case.
class AppStatusBoundary extends ConsumerStatefulWidget {
  const AppStatusBoundary({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppStatusBoundary> createState() => _AppStatusBoundaryState();
}

class _AppStatusBoundaryState extends ConsumerState<AppStatusBoundary> {
  /// The latestVersion for which the optional prompt was dismissed this session.
  String? _optionalDismissedForVersion;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appStatusControllerProvider).status;
    final version = ref.watch(currentAppVersionProvider);

    if (status != null && status.requiresForceUpdate(version)) {
      return _ForceUpdateBlock(
        message: status.updateMessage,
        onUpdate: () => ref.read(storeLauncherProvider)(),
      );
    }

    final showOptional =
        status != null &&
        status.hasOptionalUpdate(version) &&
        _optionalDismissedForVersion != status.latestVersion;

    return Stack(
      children: [
        widget.child,
        if (showOptional)
          _OptionalUpdatePrompt(
            message: status.updateMessage,
            onUpdate: () {
              ref.read(storeLauncherProvider)();
              _dismissOptional(status.latestVersion);
            },
            onLater: () => _dismissOptional(status.latestVersion),
          ),
      ],
    );
  }

  void _dismissOptional(String version) =>
      setState(() => _optionalDismissedForVersion = version);
}

class _ForceUpdateBlock extends StatelessWidget {
  const _ForceUpdateBlock({required this.message, required this.onUpdate});

  final String message;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      key: const Key('force-update-block'),
      color: _dialogBackground,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appStatusUpdateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message.isNotEmpty
                        ? message
                        : l10n.appStatusFeatureUnavailableMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    key: const Key('force-update-block-update'),
                    onPressed: onUpdate,
                    style: _primaryButtonStyle,
                    child: Text(l10n.appStatusUpdateNow),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalUpdatePrompt extends StatelessWidget {
  const _OptionalUpdatePrompt({
    required this.message,
    required this.onUpdate,
    required this.onLater,
  });

  final String message;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned.fill(
      child: Material(
        key: const Key('optional-update-prompt'),
        color: _scrimColor,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 410),
            decoration: BoxDecoration(
              color: _dialogBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.new_releases_rounded,
                    size: 44,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appStatusUpdateAvailableTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.isNotEmpty
                        ? message
                        : l10n.appStatusUpdateAvailableTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('optional-update-update'),
                    onPressed: onUpdate,
                    style: _primaryButtonStyle,
                    child: Text(l10n.appStatusUpdate),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    key: const Key('optional-update-later'),
                    onPressed: onLater,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(l10n.appStatusLater),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const Color _dialogBackground = Color(0xFFFFFCF7);

/// Dimming scrim behind the optional-update prompt (a dark neutral, not pure
/// black — see theme_consistency_test).
const Color _scrimColor = Color(0x99141418);

final ButtonStyle _primaryButtonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  backgroundColor: const Color(0xFF38AD49),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);
