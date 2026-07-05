import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/usage_badge.dart';
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withAlpha(24),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.yourPlan,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 6),
                          UsageBadge(
                            state: usageState,
                            onRetry: () => ref
                                .read(usageControllerProvider.notifier)
                                .refresh(),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.push(AppRoutes.paywall),
                      child: Text(context.l10n.plans),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: context.l10n.guidance,
            children: [
              _SettingsTile(
                icon: Icons.library_books_outlined,
                label: context.l10n.guidanceLibrary,
                onTap: () => context.push(AppRoutes.guidanceLibrary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: context.l10n.languageAndInput,
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                label: context.l10n.appLanguage,
                trailing: Text(
                  selectedLocale.code == 'system'
                      ? context.l10n.systemDefault
                      : selectedLocale.nativeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _showLanguageSelector(context, ref),
              ),
              _SettingsTile(
                icon: Icons.mic_none_rounded,
                label: context.l10n.voiceGuidanceLanguage,
                trailing: Text(context.l10n.autoDetect),
                onTap: () => _showPreviewMessage(
                  context,
                  context.l10n.voiceGuidanceLanguage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: context.l10n.about,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: context.l10n.version,
                trailing: Text('1.0.0'),
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.cloud_outlined,
                label: context.l10n.environment,
                trailing: Text(AppConfig.env),
                onTap: null,
              ),
            ],
          ),
          if (showDevTools) ...[
            const SizedBox(height: 16),
            _DeveloperTestingCard(isBusy: devToolsState.isLoading),
          ],
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
      ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          ...children,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.primaryBlue : AppColors.textDisabled;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
        ),
      ),
      trailing: trailing != null
          ? DefaultTextStyle(
              style: AppTextStyles.helper.copyWith(
                color: enabled
                    ? AppColors.textSecondary
                    : AppColors.textDisabled,
              ),
              child: trailing!,
            )
          : onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)
          : null,
      onTap: onTap,
    );
  }
}
