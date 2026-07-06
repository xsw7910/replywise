import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../auth/application/auth_controller.dart';
import '../ads/application/ad_reward_controller.dart';
import '../entitlement/credit_controller.dart';
import '../entitlement/subscription_controller.dart';
import '../entitlement/subscription_repository.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _scheduledUserId;
  String? _reconciliationScheduledUserId;

  String _adRewardMessage(BuildContext context, AdRewardOutcome outcome) {
    final l10n = context.l10n;
    return switch (outcome) {
      AdRewardOutcome.creditAdded => l10n.creditAdded,
      AdRewardOutcome.adLoading => l10n.adIsLoading,
      AdRewardOutcome.loadFailed => l10n.adLoadFailed,
      AdRewardOutcome.dailyLimitReached => l10n.adDailyLimitReached,
      AdRewardOutcome.cooldown => l10n.adRewardCooldown,
      AdRewardOutcome.failed => l10n.adRewardFailed,
    };
  }

  String? _pricePerCredit(BuildContext context, CreditPackage package) {
    final price = package.price;
    final currencyCode = package.currencyCode;
    if (price == null || currencyCode == null || package.credits <= 0) {
      return null;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final unitPrice = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
    ).format(price / package.credits);
    return context.l10n.pricePerCredit(unitPrice);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final subscription = ref.watch(subscriptionControllerProvider);
    final credits = ref.watch(creditControllerProvider);
    final adReward = ref.watch(adRewardControllerProvider);
    final appUserId = auth.appUserId;

    // A new PaywallScreen state is created for every open. Reconcile exactly
    // once for that open after authentication is available, independent of
    // whether subscription/package state was already loaded previously.
    if (appUserId != null && _reconciliationScheduledUserId != appUserId) {
      _reconciliationScheduledUserId = appUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(creditControllerProvider.notifier).syncCredits();
          // Also silently reconcile premium so a reinstalled subscriber sees
          // Premium here without tapping Restore.
          ref
              .read(subscriptionControllerProvider.notifier)
              .syncActivePremiumSilently(appUserId);
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
    ref.listen(adRewardControllerProvider, (previous, next) {
      if (next.outcome == null || previous?.outcomeToken == next.outcomeToken) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_adRewardMessage(context, next.outcome!))),
        );
    });

    final price =
        subscription.offer?.priceString ?? context.l10n.displayedPrice;
    return AppPage(
      title: context.l10n.premiumTitle,
      showAppBar: false,
      backgroundImagePath: 'assets/image/premium_page_backgroud.png',
      backgroundImageFit: BoxFit.fitWidth,
      backgroundImageAlignment: Alignment.topCenter,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Stack(
            children: [
              const SizedBox(key: Key('premium-intro-spacer'), height: 130.4),
              Positioned(
                left: -8,
                top: 0,
                child: IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ],
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/premium.png',
                      key: const Key('paywall-premium-icon'),
                      width: 32,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.premiumTitle,
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    if (subscription.offer?.hasTrial == true)
                      _Badge(label: context.l10n.threeDaysFree),
                  ],
                ),
                const SizedBox(height: 16),
                _Benefit(text: context.l10n.unlimitedReply),
                _Benefit(text: context.l10n.unlimitedPolish),
                _Benefit(text: context.l10n.balancesPreserved),
                const SizedBox(height: 18),
                if (subscription.isLoading)
                  _LoadingStatus(
                    message: context.l10n.loadingSubscriptionOptions,
                  )
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
                        : Text(
                            subscription.offer?.hasTrial == true
                                ? context.l10n.startFreeTrial
                                : context.l10n.startYearlyPlan,
                          ),
                  ),
                const SizedBox(height: 8),
                Text(
                  subscription.offer?.hasTrial == true
                      ? context.l10n.trialTerms(price)
                      : context.l10n.yearlyTerms(price),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.helper,
                ),
                if (subscription.error != null) ...[
                  const SizedBox(height: 12),
                  InlineError(
                    message: subscription.error!,
                    actionLabel: subscription.offer == null && appUserId != null
                        ? context.l10n.tryAgain
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
                    Image.asset(
                      'assets/icons/credites.png',
                      key: const Key('paywall-top-up-credits-icon'),
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.topUpCredits,
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(context.l10n.creditDescription, style: AppTextStyles.body),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('paywall-watch-ad'),
                  onPressed: adReward.isBusy
                      ? null
                      : () => ref
                            .read(adRewardControllerProvider.notifier)
                            .watchAd(),
                  icon: adReward.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.l10n.watchAd),
                      Text(
                        context.l10n.watchAdReward,
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (credits.isLoading)
                  _LoadingStatus(message: context.l10n.loadingCreditPackages)
                else if (credits.packages.isEmpty && credits.error == null)
                  Column(
                    children: [
                      Text(
                        context.l10n.creditPackagesUnavailable,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.helper,
                      ),
                      if (appUserId != null)
                        TextButton(
                          onPressed: () => ref
                              .read(creditControllerProvider.notifier)
                              .loadPackages(appUserId),
                          child: Text(context.l10n.refreshPackages),
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
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.buyCreditPackage(
                                      pkg.credits,
                                      pkg.priceString,
                                    ),
                                  ),
                                  if (_pricePerCredit(context, pkg)
                                      case final perCredit?)
                                    Text(
                                      perCredit,
                                      style: AppTextStyles.badge.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                if (credits.error != null) ...[
                  const SizedBox(height: 8),
                  InlineError(
                    message: credits.error!,
                    actionLabel: appUserId == null
                        ? null
                        : context.l10n.tryAgain,
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
                ? Text(context.l10n.restoring)
                : Text(context.l10n.restorePremium),
          ),
          Text(
            context.l10n.purchaseVerification,
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
