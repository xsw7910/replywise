import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../ads/application/ad_reward_controller.dart';
import '../auth/application/auth_controller.dart';
import '../auth/auth_state.dart';
import '../entitlement/subscription_controller.dart';
import '../entitlement/usage_controller.dart';
import 'application/dev_tools_controller.dart';
import 'application/health_controller.dart';
import 'data/health_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showPreviewMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.staticPreview(label))),
      );
  }

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

  Future<void> _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selected = ref.read(localeControllerProvider);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                context.l10n.chooseLanguage,
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: appLocaleOptions.length,
                itemBuilder: (context, index) {
                  final option = appLocaleOptions[index];
                  final isSelected = option.code == selected;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.textMuted,
                    ),
                    title: Text(
                      option.code == 'system'
                          ? context.l10n.systemDefault
                          : option.nativeName,
                    ),
                    selected: isSelected,
                    onTap: () => Navigator.pop(context, option.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      await ref.read(localeControllerProvider.notifier).select(chosen);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final usageState = ref.watch(usageControllerProvider);
    final showDevTools = ref.watch(devToolsPanelVisibleProvider);
    final devToolsState = ref.watch(devToolsControllerProvider);
    final localePreference = ref.watch(localeControllerProvider);
    final selectedLocale = appLocaleOptions.firstWhere(
      (option) => option.code == localePreference,
    );

    ref.listen(devToolsControllerProvider, (previous, next) {
      final message = next.message;
      final error = next.error;
      if (message == null && error == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message ?? error!)));
    });

    final adRewardState = ref.watch(adRewardControllerProvider);
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

    return AppPage(
      title: context.l10n.settings,
      showAppBar: false,
      backgroundImagePath: 'assets/image/settings_background.webp',
      backgroundImageAlignment: Alignment.topCenter,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 36),
        children: [
          const _PremiumAutoSync(),
          Text(
            context.l10n.settings,
            style: AppTextStyles.pageTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 34,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              context.l10n.settingsSubtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _CreditsCard(
            state: usageState,
            isAdBusy: adRewardState.isBusy,
            onRetry: () => ref.read(usageControllerProvider.notifier).refresh(),
            onWatchAd: () =>
                ref.read(adRewardControllerProvider.notifier).watchAd(),
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            children: [
              _SettingsMenuRow(
                key: const Key('settings-current-plan-row'),
                icon: Icons.workspace_premium_outlined,
                iconColor: Color(0xFF7B3FE4),
                iconBackground: Color(0xFFF3ECFF),
                accentColor: Color(0xFFD8C2FF),
                title: context.l10n.currentPlan,
                subtitle: usageState.usage.isPremium
                    ? context.l10n.premium
                    : context.l10n.freePlan,
                actionLabel: usageState.usage.isPremium
                    ? null
                    : context.l10n.upgrade,
                onTap: () => context.push(AppRoutes.paywall),
              ),
              _SettingsMenuRow(
                key: const Key('settings-language-row'),
                icon: Icons.language_rounded,
                iconColor: Color(0xFF377CF6),
                iconBackground: Color(0xFFEAF2FF),
                accentColor: Color(0xFFBFD5FF),
                title: context.l10n.appLanguage,
                subtitle: selectedLocale.code == 'system'
                    ? context.l10n.systemDefault
                    : selectedLocale.nativeName,
                onTap: () => _showLanguageSelector(context, ref),
              ),
              _SettingsMenuRow(
                key: const Key('settings-support-row'),
                icon: Icons.headset_mic_rounded,
                iconColor: Color(0xFF12A966),
                iconBackground: Color(0xFFEAF9F1),
                accentColor: Color(0xFFBCECD7),
                title: context.l10n.support,
                subtitle: context.l10n.supportDescription,
                onTap: () => _showPreviewMessage(context, context.l10n.support),
              ),
              _SettingsMenuRow(
                key: const Key('settings-about-row'),
                icon: Icons.info_outline_rounded,
                iconColor: Color(0xFF687B9B),
                iconBackground: Color(0xFFF1F4F8),
                accentColor: Color(0xFFD6DFEF),
                title: context.l10n.about,
                subtitle: context.l10n.aboutDescription,
                onTap: () => _showPreviewMessage(context, context.l10n.about),
              ),
              _SettingsMenuRow(
                key: const Key('settings-guidance-row'),
                icon: Icons.auto_awesome_rounded,
                iconColor: Color(0xFF7B3FE4),
                iconBackground: Color(0xFFF3ECFF),
                accentColor: Color(0xFFD8C2FF),
                title: context.l10n.guidance,
                subtitle: context.l10n.guidanceLibrary,
                showDivider: false,
                onTap: () => context.push(AppRoutes.guidanceLibrary),
              ),
            ],
          ),
          if (showDevTools) ...[
            const SizedBox(height: 24),
            _DeveloperTestingCard(isBusy: devToolsState.isLoading),
            const SizedBox(height: 16),
            _AuthStatusCard(
              authState: authState,
              onRetry: () => ref.read(authControllerProvider.notifier).retry(),
            ),
            const SizedBox(height: 16),
            _BackendStatusCard(
              healthState: healthState,
              onRefresh: () =>
                  ref.read(healthControllerProvider.notifier).refresh(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard({
    required this.state,
    required this.isAdBusy,
    required this.onRetry,
    required this.onWatchAd,
  });

  final UsageViewState state;
  final bool isAdBusy;
  final VoidCallback onRetry;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final usage = state.usage;
    final total =
        (usage.freeUsesLeft ?? usage.freeUsesLimit) + usage.paidCredits;

    return Container(
      key: const Key('settings-credits-card'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBF3), Color(0xFFF9FCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE9C2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C49619A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE9B9), Color(0xFFFFF8E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFF4A51C),
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.credits, style: AppTextStyles.cardTitle),
                const SizedBox(height: 1),
                if (state.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Text(
                    '$total',
                    style: AppTextStyles.pageTitle.copyWith(
                      fontSize: 30,
                      color: AppColors.primaryBlue,
                      height: 1.1,
                    ),
                  ),
                Text(
                  state.error == null
                      ? context.l10n.totalCredits
                      : context.l10n.balanceUnavailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.helper,
                ),
              ],
            ),
          ),
          if (state.error != null)
            IconButton(
              tooltip: context.l10n.retry,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            )
          else
            OutlinedButton.icon(
              onPressed: isAdBusy ? null : onWatchAd,
              icon: isAdBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.watchAd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.l10n.watchAdReward,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                side: const BorderSide(color: Color(0xFFCDDDF8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('settings-options-group'),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(232),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withAlpha(225)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1849619A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.actionLabel,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 15, 12, 15),
              child: Row(
                children: [
                  _IconPanel(
                    icon: icon,
                    color: iconColor,
                    background: iconBackground,
                    size: 56,
                  ),
                  const SizedBox(width: 11),
                  Container(
                    width: 3,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.helper.copyWith(
                            color: actionLabel != null
                                ? const Color(0xFF6559E8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7559EE),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(actionLabel!),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 26,
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.only(left: 97, right: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9EDF5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconPanel extends StatelessWidget {
  const _IconPanel({
    required this.icon,
    required this.color,
    required this.background,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _DeveloperTestingCard extends ConsumerWidget {
  const _DeveloperTestingCard({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(devToolsControllerProvider.notifier);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.developerTesting, style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : controller.resetUsage,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(context.l10n.resetFreeUsage),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => controller.addCredits(10),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(context.l10n.addCredits(10)),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => controller.addCredits(50),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(context.l10n.addCredits(50)),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => controller.setPremium(true),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(context.l10n.simulatePremiumOn),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => controller.setPremium(false),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(context.l10n.simulatePremiumOff),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : controller.refreshAccountState,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.refreshAccountState),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthStatusCard extends StatelessWidget {
  const _AuthStatusCard({required this.authState, required this.onRetry});

  final AuthState authState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, color, label) = switch (authState.status) {
      AuthStatus.authenticated => (
        Icons.verified_user_outlined,
        AppColors.success,
        l10n.anonymousSessionReady,
      ),
      AuthStatus.authenticating => (
        Icons.sync_rounded,
        AppColors.primaryBlue,
        l10n.connectingAnonymousSession,
      ),
      AuthStatus.refreshing => (
        Icons.sync_lock_outlined,
        AppColors.primaryBlue,
        l10n.refreshingSecureSession,
      ),
      AuthStatus.tokenExpired => (
        Icons.history_toggle_off_rounded,
        AppColors.primaryBlue,
        l10n.restoringAnonymousSession,
      ),
      AuthStatus.failure => (
        Icons.gpp_bad_outlined,
        AppColors.error,
        l10n.anonymousSessionUnavailable,
      ),
      AuthStatus.unauthenticated => (
        Icons.shield_outlined,
        AppColors.textSecondary,
        l10n.anonymousSessionNotStarted,
      ),
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.secureSession, style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.helper.copyWith(color: color),
                ),
              ),
              if (authState.status == AuthStatus.failure)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(l10n.retry),
                ),
            ],
          ),
          if (authState.status == AuthStatus.failure &&
              authState.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(authState.errorMessage!, style: AppTextStyles.helper),
          ],
        ],
      ),
    );
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({
    required this.healthState,
    required this.onRefresh,
  });

  final AsyncValue<HealthResponse> healthState;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.developer,
                      style: AppTextStyles.cardTitle,
                    ),
                    Text(
                      context.l10n.localBackendConnection,
                      style: AppTextStyles.helper,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.refreshBackendStatus,
                onPressed: healthState.isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          healthState.when(
            loading: () => _StatusRow(
              icon: Icons.sync_rounded,
              color: AppColors.primaryBlue,
              title: context.l10n.checkingBackend,
            ),
            data: (health) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  title: context.l10n.connected,
                ),
                const SizedBox(height: 5),
                Text(
                  '${health.service} · ${health.status}',
                  style: AppTextStyles.helper,
                ),
              ],
            ),
            error: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  icon: Icons.error_rounded,
                  color: AppColors.error,
                  title: context.l10n.connectionFailed,
                ),
                const SizedBox(height: 5),
                InlineError(
                  message: context.l10n.serviceUnreachable,
                  actionLabel: context.l10n.retry,
                  onAction: onRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.helper.copyWith(color: color)),
      ],
    );
  }
}

/// Invisible one-shot trigger. When Settings opens it silently reconciles an
/// already-active premium entitlement (e.g. after a reinstall) so Premium shows
/// without tapping Restore. Uses getCustomerInfo() only — no purchase/store UI.
/// `initState` fires exactly once per screen open.
class _PremiumAutoSync extends ConsumerStatefulWidget {
  const _PremiumAutoSync();

  @override
  ConsumerState<_PremiumAutoSync> createState() => _PremiumAutoSyncState();
}

class _PremiumAutoSyncState extends ConsumerState<_PremiumAutoSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appUserId = ref.read(authControllerProvider).appUserId;
      if (appUserId != null) {
        ref
            .read(subscriptionControllerProvider.notifier)
            .syncActivePremiumSilently(appUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
