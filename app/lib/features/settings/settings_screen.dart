import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
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
import 'application/health_controller.dart';
import 'data/health_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showPreviewMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is a static preview.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final usageState = ref.watch(usageControllerProvider);

    return AppPage(
      title: 'Settings',
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
                        color: AppColors.primary.withAlpha(24),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your plan', style: AppTextStyles.titleMedium),
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
                      child: const Text('Plans'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Language & input',
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                label: 'App language',
                trailing: const Text('English'),
                onTap: () => _showPreviewMessage(context, 'App language'),
              ),
              _SettingsTile(
                icon: Icons.mic_none_rounded,
                label: 'Voice guidance language',
                trailing: const Text('Auto Detect'),
                onTap: () => _showPreviewMessage(context, 'Voice language'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'About',
            children: [
              const _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                trailing: Text('1.0.0'),
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.cloud_outlined,
                label: 'Environment',
                trailing: Text(AppConfig.env),
                onTap: null,
              ),
            ],
          ),
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

class _AuthStatusCard extends StatelessWidget {
  const _AuthStatusCard({required this.authState, required this.onRetry});

  final AuthState authState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (authState.status) {
      AuthStatus.authenticated => (
        Icons.verified_user_outlined,
        AppColors.success,
        'Anonymous session ready',
      ),
      AuthStatus.authenticating => (
        Icons.sync_rounded,
        AppColors.primary,
        'Connecting anonymous session…',
      ),
      AuthStatus.refreshing => (
        Icons.sync_lock_outlined,
        AppColors.primary,
        'Refreshing secure session…',
      ),
      AuthStatus.tokenExpired => (
        Icons.history_toggle_off_rounded,
        AppColors.primary,
        'Restoring anonymous session…',
      ),
      AuthStatus.failure => (
        Icons.gpp_bad_outlined,
        AppColors.error,
        'Anonymous session unavailable',
      ),
      AuthStatus.unauthenticated => (
        Icons.shield_outlined,
        AppColors.textSecondary,
        'Anonymous session not started',
      ),
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Secure session', style: AppTextStyles.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(color: color),
                ),
              ),
              if (authState.status == AuthStatus.failure)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Retry'),
                ),
            ],
          ),
          if (authState.status == AuthStatus.failure &&
              authState.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(authState.errorMessage!, style: AppTextStyles.bodyMedium),
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
          Text(title, style: AppTextStyles.titleMedium),
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
                    Text('Developer', style: AppTextStyles.titleMedium),
                    Text(
                      'Local backend connection',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh backend status',
                onPressed: healthState.isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          healthState.when(
            loading: () => const _StatusRow(
              icon: Icons.sync_rounded,
              color: AppColors.primary,
              title: 'Checking backend…',
            ),
            data: (health) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatusRow(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  title: 'Connected',
                ),
                const SizedBox(height: 5),
                Text(
                  '${health.service} · ${health.status}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            error: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatusRow(
                  icon: Icons.error_rounded,
                  color: AppColors.error,
                  title: 'Connection failed',
                ),
                const SizedBox(height: 5),
                InlineError(
                  message:
                      'We couldn’t reach the service. Check your connection and try again.',
                  actionLabel: 'Retry',
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
        Text(title, style: AppTextStyles.bodyMedium.copyWith(color: color)),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: trailing != null
          ? DefaultTextStyle(style: AppTextStyles.bodyMedium, child: trailing!)
          : onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)
          : null,
      onTap: onTap,
    );
  }
}
