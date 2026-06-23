import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/usage_badge.dart';
import '../entitlement/usage_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageState = ref.watch(usageControllerProvider);

    return AppPage(
      title: 'Home',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good to see you', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text('ReplyWise', style: AppTextStyles.displayLarge),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              UsageBadge(
                state: usageState,
                onRetry: () =>
                    ref.read(usageControllerProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ReplyHeroCard(onTap: () => context.go(AppRoutes.reply)),
          const SizedBox(height: 24),
          Text('Features', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: [
              _FeatureCard(
                key: const Key('home-feature-reply'),
                icon: Icons.edit_note_rounded,
                title: 'Reply',
                subtitle: 'Generate natural English replies',
                onTap: () => context.go(AppRoutes.reply),
              ),
              _FeatureCard(
                key: const Key('home-feature-explain'),
                icon: Icons.psychology_alt_rounded,
                title: 'Explain',
                subtitle: 'Understand meaning, tone, and suggested replies',
                onTap: () => context.go(AppRoutes.explain),
              ),
              _FeatureCard(
                key: const Key('home-feature-polish'),
                icon: Icons.auto_fix_high_rounded,
                title: 'Polish',
                subtitle: 'Make your English sound more natural',
                onTap: () => context.go(AppRoutes.polish),
              ),
              _FeatureCard(
                key: const Key('home-feature-guidance'),
                icon: Icons.menu_book_rounded,
                title: 'Guidance Library',
                subtitle: 'Save and reuse your guidance',
                onTap: () => context.push(AppRoutes.guidanceLibrary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyHeroCard extends StatelessWidget {
  const _ReplyHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Generate Reply',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('home-hero-reply-card'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A90D9),
                  Color(0xFF6EB6F4),
                  Color(0xFF8AD6F6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(38),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Most used',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generate Reply',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste a message, add your guidance, and get natural English replies.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(height: 14),
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
