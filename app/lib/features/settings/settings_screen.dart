import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
