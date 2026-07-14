import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/credits_status_icon.dart';
import '../../entitlement/entitlement_state.dart';

/// Compact status pill shown on the right of the Reply page header.
///
/// * Premium users see a gold crown + "Premium" (no credit count).
/// * Everyone else sees a credit icon and their total usable balance —
///   free remaining + purchased credits.
///
/// Tapping opens the paywall / plans screen via [onTap].
class ReplyStatusBadge extends StatelessWidget {
  const ReplyStatusBadge({
    required this.usage,
    required this.onTap,
    this.premiumIconAsset,
    super.key,
  });

  final EntitlementState usage;
  final VoidCallback onTap;
  final String? premiumIconAsset;

  @override
  Widget build(BuildContext context) {
    final isPremium = usage.isPremium;
    final color = isPremium ? AppColors.premiumGold : AppColors.replyColor;

    // Total usable credits = free remaining + purchased credits. Keep the
    // number visible while the first usage refresh is pending; paid credits
    // are still known locally and the refreshed total replaces it shortly.
    final String label = isPremium
        ? context.l10n.premium
        : '${(usage.freeUsesLeft ?? 0) + usage.paidCredits}';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        label: isPremium
            ? context.l10n.premiumActive
            : context.l10n.creditsRemaining(label),
        child: Material(
          color: color.withAlpha(22),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPremium)
                    premiumIconAsset == null
                        ? Icon(
                            Icons.workspace_premium_rounded,
                            key: const Key('premium-status-icon'),
                            size: 17,
                            color: color,
                          )
                        : Image.asset(
                            premiumIconAsset!,
                            key: const Key('premium-status-image'),
                            width: 24,
                            height: 18,
                            fit: BoxFit.contain,
                          )
                  else
                    const CreditsStatusIcon(key: Key('credits-status-icon')),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTextStyles.badge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
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
