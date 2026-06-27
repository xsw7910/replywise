import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../auth/application/auth_controller.dart';
import '../entitlement/credit_controller.dart';
import '../entitlement/subscription_controller.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _scheduledUserId;
  String? _reconciliationScheduledUserId;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final subscription = ref.watch(subscriptionControllerProvider);
    final credits = ref.watch(creditControllerProvider);
    final appUserId = auth.appUserId;

    // A new PaywallScreen state is created for every open. Reconcile exactly
    // once for that open after authentication is available, independent of
    // whether subscription/package state was already loaded previously.
    if (appUserId != null && _reconciliationScheduledUserId != appUserId) {
      _reconciliationScheduledUserId = appUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(creditControllerProvider.notifier).syncCredits();
        }
      });
    }

    if (appUserId != null &&
        subscription.appUserId != appUserId &&
        _scheduledUserId != appUserId) {
      _scheduledUserId = appUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(subscriptionControllerProvider.notifier).load(appUserId);
        ref.read(creditControllerProvider.notifier).loadPackages(appUserId);
      });
    }

    ref.listen(subscriptionControllerProvider, (previous, next) {
      if (next.message != null && next.message != previous?.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
      }
    });

    final price = subscription.offer?.priceString ?? 'the displayed price';
    return AppPage(
      title: 'ReplyWise Premium',
      showBackButton: true,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBlue,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Write with confidence',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Unlimited Reply and Polish generations while Premium is active.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Monthly Premium',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    const _Badge(label: '3 days free'),
                  ],
                ),
                const SizedBox(height: 16),
                const _Benefit(text: 'Unlimited Reply generations'),
                const _Benefit(text: 'Unlimited Polish generations'),
                const _Benefit(text: 'Free and credit balances stay preserved'),
                const SizedBox(height: 18),
                if (subscription.isLoading)
                  const _LoadingStatus(message: 'Loading subscription options…')
                else
                  ElevatedButton(
                    onPressed: subscription.offer == null || subscription.isBusy
                        ? null
                        : () => ref
                              .read(subscriptionControllerProvider.notifier)
                              .purchase(),
                    child: subscription.isPurchasing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Start 3-day Free Trial'),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Free for 3 days, then $price/month. Cancel anytime.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.helper,
                ),
                if (subscription.error != null) ...[
                  const SizedBox(height: 12),
                  InlineError(
                    message: subscription.error!,
                    actionLabel: subscription.offer == null && appUserId != null
                        ? 'Try again'
                        : null,
                    onAction: subscription.offer == null && appUserId != null
                        ? () => ref
                              .read(subscriptionControllerProvider.notifier)
                              .load(appUserId)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Buy Credits ──────────────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.toll_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Top-up Credits',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Each credit covers one Reply or Polish. Credits never expire.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 14),
                if (credits.isLoading)
                  const _LoadingStatus(message: 'Loading credit packages…')
                else if (credits.packages.isEmpty && credits.error == null)
                  Column(
                    children: [
                      Text(
                        'Credit packages are unavailable right now.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.helper,
                      ),
                      if (appUserId != null)
                        TextButton(
                          onPressed: () => ref
                              .read(creditControllerProvider.notifier)
                              .loadPackages(appUserId),
                          child: const Text('Refresh packages'),
                        ),
                    ],
                  )
                else
                  ...credits.packages.map(
                    (pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: appUserId == null || credits.isBusy
                            ? null
                            : () => ref
                                  .read(creditControllerProvider.notifier)
                                  .purchase(appUserId, pkg),
                        child: credits.isPurchasing
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '${pkg.credits} credits — ${pkg.priceString}',
                              ),
                      ),
                    ),
                  ),
                if (credits.error != null) ...[
                  const SizedBox(height: 8),
                  InlineError(
                    message: credits.error!,
                    actionLabel: appUserId == null ? null : 'Try again',
                    onAction: appUserId == null
                        ? null
                        : () => ref
                              .read(creditControllerProvider.notifier)
                              .loadPackages(appUserId),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: appUserId == null || subscription.isBusy
                ? null
                : () => ref
                      .read(subscriptionControllerProvider.notifier)
                      .restore(),
            child: subscription.isRestoring
                ? const Text('Restoring…')
                : const Text('Restore Premium subscription'),
          ),
          Text(
            'Premium and credit purchases are verified by ReplyWise. Credit purchases are reconciled automatically.',
            textAlign: TextAlign.center,
            style: AppTextStyles.helper,
          ),
        ],
      ),
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(message, style: AppTextStyles.helper)),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withAlpha(24),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTextStyles.badge.copyWith(color: AppColors.primaryBlue),
    ),
  );
}
