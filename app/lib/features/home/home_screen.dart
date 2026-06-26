import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';

const _homeHorizontalPadding = 20.0;
const _homeCardSpacing = 12.0;

const _ink = Color(0xFF1A2340);
const _muted = Color(0xFF8A93A6);
const _chevron = Color(0xFFC2C9D6);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AppPage(
      title: 'Home',
      showAppBar: false,
      useSafeArea: false,
      child: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                _homeHorizontalPadding,
                topInset + 18,
                _homeHorizontalPadding,
                32,
              ),
              children: [
                _HomeHeader(onUpgrade: () => context.push(AppRoutes.paywall)),
                const SizedBox(height: 22),
                _FeatureTile(
                  key: const Key('home-feature-reply'),
                  icon: Icons.chat_bubble_rounded,
                  accent: AppColors.replyColor,
                  title: 'Reply',
                  subtitle: 'Generate natural English replies.',
                  onTap: () => context.go(AppRoutes.reply),
                ),
                const SizedBox(height: _homeCardSpacing),
                _FeatureTile(
                  key: const Key('home-feature-polish'),
                  icon: Icons.auto_fix_high_rounded,
                  accent: AppColors.polishColor,
                  title: 'Polish',
                  subtitle: 'Make your English sound more natural.',
                  onTap: () => context.go(AppRoutes.polish),
                ),
                const SizedBox(height: _homeCardSpacing),
                _FeatureTile(
                  key: const Key('home-feature-explain'),
                  icon: Icons.forum_rounded,
                  accent: AppColors.explainColor,
                  title: 'Explain',
                  subtitle: 'Understand the meaning and tone.',
                  onTap: () => context.go(AppRoutes.explain),
                ),
                const SizedBox(height: _homeCardSpacing),
                _FeatureTile(
                  key: const Key('home-feature-guidance'),
                  icon: Icons.menu_book_rounded,
                  accent: AppColors.guidanceColor,
                  title: 'Guidance Library',
                  subtitle: 'Save and reuse your guidance.',
                  onTap: () => context.push(AppRoutes.guidanceLibrary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.backgroundBase);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5C8BFF), AppColors.replyColor],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.replyColor.withAlpha(85),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.forum_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ReplyWise',
                style: AppTextStyles.displayLarge.copyWith(
                  color: _ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose what you need',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CrownBadge(onTap: onUpgrade),
      ],
    );
  }
}

class _CrownBadge extends StatelessWidget {
  const _CrownBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Upgrade to premium',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD66B), AppColors.guidanceColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.guidanceColor.withAlpha(90),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          const BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          const BoxShadow(
            color: AppColors.cardSoftShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.cardBorder, width: 1.4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.white, 0.28)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _muted,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _chevron,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
