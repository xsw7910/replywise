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
import '../auth/application/auth_controller.dart';
import '../auth/auth_state.dart';
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

    return AppPage(
      title: context.l10n.settings,
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 32),
        children: [
          Text(
            context.l10n.settings,
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 34),
          _CreditsCard(
            state: usageState,
            onRetry: () => ref.read(usageControllerProvider.notifier).refresh(),
            onWatchAd: () => _showPreviewMessage(context, context.l10n.watchAd),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            state: usageState,
            onTap: () => context.push(AppRoutes.paywall),
          ),
          const SizedBox(height: 16),
          _SettingsActionCard(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF377CF6),
            iconBackground: const Color(0xFFEAF2FF),
            title: context.l10n.appLanguage,
            trailing: selectedLocale.code == 'system'
                ? context.l10n.systemDefault
                : selectedLocale.nativeName,
            onTap: () => _showLanguageSelector(context, ref),
          ),
          const SizedBox(height: 16),
          _SettingsActionCard(
            icon: Icons.headset_mic_rounded,
            iconColor: const Color(0xFF12A966),
            iconBackground: const Color(0xFFEAF9F1),
            title: context.l10n.support,
            subtitle: context.l10n.supportDescription,
            onTap: () => _showPreviewMessage(context, context.l10n.support),
          ),
          const SizedBox(height: 16),
          _SettingsActionCard(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF687B9B),
            iconBackground: const Color(0xFFF1F4F8),
            title: context.l10n.about,
            subtitle: context.l10n.aboutDescription,
            onTap: () => _showPreviewMessage(context, context.l10n.about),
          ),
          const SizedBox(height: 16),
          _SettingsActionCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFF7B3FE4),
            iconBackground: const Color(0xFFF3ECFF),
            title: context.l10n.guidance,
            subtitle: context.l10n.guidanceLibrary,
            onTap: () => context.push(AppRoutes.guidanceLibrary),
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
    required this.onRetry,
    required this.onWatchAd,
  });

  final UsageViewState state;
  final VoidCallback onRetry;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final usage = state.usage;
    final total =
        (usage.freeUsesLeft ?? usage.freeUsesLimit) + usage.paidCredits;

    return _SettingsSurface(
      child: Row(
        children: [
          const _IconPanel(
            icon: Icons.monetization_on_rounded,
            color: Color(0xFFF4A51C),
            background: Color(0xFFFFF5E2),
            size: 68,
          ),
          const SizedBox(width: 16),
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
                      fontSize: 28,
                      color: AppColors.primaryBlue,
                      height: 1.15,
                    ),
                  ),
                Text(
                  state.error == null
                      ? context.l10n.totalCredits
                      : context.l10n.balanceUnavailable,
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
              onPressed: onWatchAd,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                side: const BorderSide(color: Color(0xFFDDE5F2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.state, required this.onTap});

  final UsageViewState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usage = state.usage;

    return _SettingsSurface(
      onTap: onTap,
      child: Row(
        children: [
          const _IconPanel(
            icon: Icons.workspace_premium_outlined,
            color: Color(0xFF7B3FE4),
            background: Color(0xFFF3ECFF),
            size: 68,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.currentPlan, style: AppTextStyles.cardTitle),
                const SizedBox(height: 3),
                Text(
                  usage.isPremium
                      ? context.l10n.premium
                      : context.l10n.freePlan,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!usage.isPremium)
                  Text(
                    context.l10n.freeRepliesPerDay(usage.freeUsesLimit),
                    style: AppTextStyles.helper,
                  ),
              ],
            ),
          ),
          if (!usage.isPremium)
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(context.l10n.upgrade),
            ),
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  const _SettingsActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsSurface(
      onTap: onTap,
      child: Row(
        children: [
          _IconPanel(
            icon: icon,
            color: iconColor,
            background: iconBackground,
            size: 60,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppTextStyles.helper),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                trailing!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      shadowColor: const Color(0x2449619A),
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: child,
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
