import 'package:flutter/material.dart';

import '../../features/entitlement/usage_controller.dart';
import '../theme/app_colors.dart';
import '../localization/localization_extensions.dart';
import '../theme/app_text_styles.dart';

class UsageBadge extends StatelessWidget {
  const UsageBadge({
    required this.state,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final UsageViewState state;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final usage = state.usage;
    final l10n = context.l10n;
    final (icon, label) = usage.isPremium
        ? (
            Icons.workspace_premium_rounded,
            compact ? l10n.premium : l10n.premiumUnlimited,
          )
        : state.isLoading
        ? (Icons.sync_rounded, compact ? l10n.updating : l10n.updatingBalance)
        : state.error != null
        ? (
            Icons.cloud_off_outlined,
            compact ? l10n.retry : l10n.balanceUnavailable,
          )
        : usage.freeUsesLeft == null
        ? (
            Icons.hourglass_empty_rounded,
            compact ? l10n.checking : l10n.checkingBalance,
          )
        : (
            Icons.bolt_rounded,
            compact
                ? l10n.freeCount(usage.freeUsesLeft!)
                : l10n.usageBalance(usage.freeUsesLeft!, usage.paidCredits),
          );

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withAlpha(18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            if (state.error != null && onRetry != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
