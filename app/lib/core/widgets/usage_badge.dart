import 'package:flutter/material.dart';

import '../../features/entitlement/usage_controller.dart';
import '../theme/app_colors.dart';
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
    final (icon, label) = usage.isPremium
        ? (
            Icons.workspace_premium_rounded,
            compact ? 'Premium' : 'Premium · Unlimited',
          )
        : state.isLoading
        ? (Icons.sync_rounded, compact ? 'Updating' : 'Updating balance…')
        : state.error != null
        ? (Icons.cloud_off_outlined, compact ? 'Retry' : 'Balance unavailable')
        : usage.freeUsesLeft == null
        ? (
            Icons.hourglass_empty_rounded,
            compact ? 'Checking' : 'Checking balance…',
          )
        : (
            Icons.bolt_rounded,
            compact
                ? '${usage.freeUsesLeft} free'
                : '${usage.freeUsesLeft} free · ${usage.paidCredits} credits',
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
