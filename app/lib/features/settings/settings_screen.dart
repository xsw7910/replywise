import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import 'application/health_controller.dart';
import 'data/health_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.person_rounded,
                  label: 'Sign in',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.star_rounded,
                  label: 'Subscription',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferences', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  label: 'Reply language',
                  trailing: const Text('English'),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  label: 'Default tone',
                  trailing: const Text('Professional'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  trailing: const Text('1.0.0'),
                  onTap: null,
                ),
                _SettingsTile(
                  icon: Icons.cloud_rounded,
                  label: 'Environment',
                  trailing: Text(AppConfig.env),
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BackendStatusCard(
            healthState: healthState,
            onRefresh: () =>
                ref.read(healthControllerProvider.notifier).refresh(),
          ),
          const SizedBox(height: 8),
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
          Text('Developer', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Backend Status', style: AppTextStyles.bodyLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: healthState.isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          healthState.when(
            loading: () => Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Loading...', style: AppTextStyles.bodyMedium),
              ],
            ),
            data: (health) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('status: ${health.status}',
                    style: AppTextStyles.bodyMedium),
                Text('service: ${health.service}',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connection Failed',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  error.toString(),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
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
          ? DefaultTextStyle(
              style: AppTextStyles.bodyMedium,
              child: trailing!,
            )
          : onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint)
              : null,
      onTap: onTap,
    );
  }
}
