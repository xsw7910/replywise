import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../ads/application/ad_reward_controller.dart';
import '../entitlement_state.dart';
import '../usage_controller.dart';

const _dialogGreen = Color(0xFF38AD49);
const _dialogBackground = Color(0xFFFFFCF7);

enum OutOfCreditsAction { watchAd, upgrade, buyCredits, cancel }

bool hasGenerationAccess(EntitlementState usage) {
  final hasFreeUsage = usage.freeUsesLeft != null
      ? usage.freeUsesLeft! > 0
      : usage.freeUsesUsed < usage.freeUsesLimit;
  return usage.isPremium || usage.paidCredits > 0 || hasFreeUsage;
}

final generationAccessProvider = Provider<bool>(
  (ref) => hasGenerationAccess(ref.watch(usageControllerProvider).usage),
);

/// Returns true when the caller may continue with generation.
///
/// When access is unavailable, this owns the dialog actions and always returns
/// false so generation is never started implicitly after an ad or purchase
/// navigation.
Future<bool> ensureGenerationAccess({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  if (ref.read(generationAccessProvider)) return true;

  final action = await showDialog<OutOfCreditsAction>(
    context: context,
    builder: (_) => const OutOfCreditsDialog(),
  );
  if (!context.mounted) return false;

  switch (action) {
    case OutOfCreditsAction.watchAd:
      await ref.read(adRewardControllerProvider.notifier).watchAd();
      if (!context.mounted) return false;
      final outcome = ref.read(adRewardControllerProvider).outcome;
      final message = _messageForOutcome(context, outcome);
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
      break;
    case OutOfCreditsAction.upgrade:
    case OutOfCreditsAction.buyCredits:
      context.push(AppRoutes.paywall);
      break;
    case OutOfCreditsAction.cancel:
    case null:
      break;
  }
  return false;
}

String? _messageForOutcome(BuildContext context, AdRewardOutcome? outcome) {
  final l10n = context.l10n;
  return switch (outcome) {
    AdRewardOutcome.creditAdded => l10n.creditAddedTapGenerateAgain,
    AdRewardOutcome.adLoading => l10n.adIsLoading,
    AdRewardOutcome.loadFailed => l10n.adLoadFailed,
    AdRewardOutcome.dailyLimitReached => l10n.adDailyLimitReached,
    AdRewardOutcome.cooldown => l10n.adRewardCooldown,
    AdRewardOutcome.failed => l10n.adRewardFailed,
    null => null,
  };
}

class OutOfCreditsDialog extends StatelessWidget {
  const OutOfCreditsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      key: const Key('out-of-credits-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: _dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/icons/out_of_credits_gift.png',
                  width: 106,
                  height: 106,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.outOfCreditsTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.outOfCreditsMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _DialogButton(
                key: const Key('out-of-credits-watch-ad'),
                label: l10n.watchAd,
                icon: Icons.play_arrow_rounded,
                filled: true,
                onPressed: () =>
                    Navigator.pop(context, OutOfCreditsAction.watchAd),
              ),
              const SizedBox(height: 10),
              _DialogButton(
                key: const Key('out-of-credits-upgrade'),
                label: l10n.upgrade,
                icon: Icons.workspace_premium_rounded,
                onPressed: () =>
                    Navigator.pop(context, OutOfCreditsAction.upgrade),
              ),
              const SizedBox(height: 10),
              _DialogButton(
                key: const Key('out-of-credits-buy-credits'),
                label: l10n.buyCredits,
                icon: Icons.monetization_on_rounded,
                onPressed: () =>
                    Navigator.pop(context, OutOfCreditsAction.buyCredits),
              ),
              const SizedBox(height: 6),
              TextButton(
                key: const Key('out-of-credits-cancel'),
                onPressed: () =>
                    Navigator.pop(context, OutOfCreditsAction.cancel),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: WidgetStatePropertyAll(
        AppTextStyles.button.copyWith(fontSize: 16),
      ),
    );

    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: style.copyWith(
          backgroundColor: const WidgetStatePropertyAll(_dialogGreen),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: style.copyWith(
        foregroundColor: const WidgetStatePropertyAll(_dialogGreen),
        side: const WidgetStatePropertyAll(
          BorderSide(color: _dialogGreen, width: 1.4),
        ),
      ),
    );
  }
}
