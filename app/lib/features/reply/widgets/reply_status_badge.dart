import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../entitlement/entitlement_state.dart';

/// Compact status pill shown on the right of the Reply page header.
///
/// * Premium users see a gold crown + "Premium" (no credit count).
/// * Everyone else sees a credit icon and their total usable balance —
///   free remaining + purchased credits.
///
/// Tapping opens the paywall / plans screen via [onTap].
class ReplyStatusBadge extends StatelessWidget {
  const ReplyStatusBadge({required this.usage, required this.onTap, super.key});

  final EntitlementState usage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = usage.isPremium;
    final color = isPremium ? AppColors.premiumGold : AppColors.replyColor;
    final icon = isPremium
        ? Icons.workspace_premium_rounded
        : Icons.toll_rounded;

    // Total usable credits = free remaining + purchased credits. freeUsesLeft
    // is null before the first load (and whenever premium), so show only the
    // icon in that case rather than a misleading "0".
    final String? label = isPremium
        ? 'Premium'
        : (usage.freeUsesLeft != null
              ? '${usage.freeUsesLeft! + usage.paidCredits}'
              : null);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        label: isPremium
            ? 'Premium subscription active'
            : (label != null ? '$label credits remaining' : 'View plans'),
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
                  Icon(icon, size: 17, color: color),
                  if (label != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: AppTextStyles.badge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
