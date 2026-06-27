import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';

const _homeHorizontalPadding = 20.0;
const _homeCardSpacing = 12.0;

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
      child: ColoredBox(
        color: AppColors.backgroundBase,
        child: Column(
          children: [
            _HomeNavBar(topInset: topInset),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  _homeHorizontalPadding,
                  16,
                  _homeHorizontalPadding,
                  32,
                ),
                children: [
                  _HeroCard(onTap: () => context.go(AppRoutes.reply)),
                  const SizedBox(height: 20),
                  _FeatureTile(
                    key: const Key('home-feature-reply'),
                    imagePath: 'assets/icons/reply.png',
                    feature: AppFeature.reply,
                    title: 'Reply',
                    subtitle: 'Generate natural English replies.',
                    onTap: () => context.go(AppRoutes.reply),
                  ),
                  const SizedBox(height: _homeCardSpacing),
                  _FeatureTile(
                    key: const Key('home-feature-polish'),
                    imagePath: 'assets/icons/polish.png',
                    feature: AppFeature.polish,
                    title: 'Polish',
                    subtitle: 'Make your English sound more natural.',
                    onTap: () => context.go(AppRoutes.polish),
                  ),
                  const SizedBox(height: _homeCardSpacing),
                  _FeatureTile(
                    key: const Key('home-feature-explain'),
                    imagePath: 'assets/icons/explain.png',
                    feature: AppFeature.explain,
                    title: 'Explain',
                    subtitle: 'Understand the meaning and tone.',
                    onTap: () => context.go(AppRoutes.explain),
                  ),
                  const SizedBox(height: _homeCardSpacing),
                  _FeatureTile(
                    key: const Key('home-feature-guidance'),
                    imagePath: 'assets/icons/guidance.png',
                    feature: AppFeature.guidance,
                    title: 'Guidance Library',
                    subtitle: 'Save and reuse your guidance.',
                    onTap: () => context.push(AppRoutes.guidanceLibrary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavBar extends StatelessWidget {
  const _HomeNavBar({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundBase,
      padding: EdgeInsets.fromLTRB(
        _homeHorizontalPadding,
        topInset + 10,
        _homeHorizontalPadding,
        10,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF3D6FFF), Color(0xFF00C2CB)],
                ).createShader(bounds),
                child: Text(
                  'ReplyWise',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                'Your AI reply assistant',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.cardSoftShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 2.0,
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/image/hero_card.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Get started button
              Positioned(
                left: 34,
                bottom: 14,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xA6D9EEFF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Get started',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF5276D9),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0x78FFFFFF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xA6FFFFFF),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x266B8FBF),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF5276D9),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    super.key,
    this.icon,
    this.imagePath,
    required this.feature,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || imagePath != null);

  final IconData? icon;
  final String? imagePath;
  final AppFeature feature;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 28.0;
    final accent = feature.accentColor;

    return Container(
      decoration: feature.glassCardDecoration(borderRadius: radius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  imagePath != null
                      ? SizedBox.square(
                          dimension: 52,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Transform.scale(
                              scale: 1.08,
                              child: Image.asset(imagePath!, fit: BoxFit.cover),
                            ),
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
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
