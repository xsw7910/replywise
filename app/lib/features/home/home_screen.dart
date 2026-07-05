import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../entitlement/usage_controller.dart';
import '../reply/widgets/reply_status_badge.dart';

const _homeHorizontalPadding = 20.0;
const _gridGap = 12.0;

const _chevron = AppColors.textDisabled;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final usage = ref.watch(usageControllerProvider).usage;

    return AppPage(
      title: 'Home',
      showAppBar: false,
      useSafeArea: false,
      child: ColoredBox(
        color: AppColors.backgroundBase,
        child: Column(
          children: [
            _HomeNavBar(
              topInset: topInset,
              trailing: ReplyStatusBadge(
                usage: usage,
                onTap: () => context.push(AppRoutes.paywall),
              ),
            ),
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
                  const SizedBox(height: 22),
                  // 2 × 2 feature grid.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _FeatureCard(
                            key: const Key('home-feature-reply'),
                            imagePath: 'assets/icons/reply.png',
                            feature: AppFeature.reply,
                            title: 'Reply',
                            subtitle: 'Generate thoughtful replies instantly.',
                            onTap: () => context.go(AppRoutes.reply),
                          ),
                        ),
                        const SizedBox(width: _gridGap),
                        Expanded(
                          child: _FeatureCard(
                            key: const Key('home-feature-polish'),
                            imagePath: 'assets/icons/polish.png',
                            feature: AppFeature.polish,
                            title: 'Polish',
                            subtitle: 'Make your writing clear and natural.',
                            onTap: () => context.go(AppRoutes.polish),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _gridGap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _FeatureCard(
                            key: const Key('home-feature-explain'),
                            imagePath: 'assets/icons/explain.png',
                            feature: AppFeature.explain,
                            title: 'Explain',
                            subtitle: 'Understand tone and hidden meaning.',
                            onTap: () => context.go(AppRoutes.explain),
                          ),
                        ),
                        const SizedBox(width: _gridGap),
                        Expanded(
                          child: _FeatureCard(
                            key: const Key('home-feature-guidance'),
                            imagePath: 'assets/icons/guidance.png',
                            feature: AppFeature.guidance,
                            title: 'Templates',
                            subtitle: 'Reuse your favorite AI instructions.',
                            onTap: () => context.push(AppRoutes.guidanceLibrary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _RecentSection(onCreate: () => context.go(AppRoutes.reply)),
                  const SizedBox(height: 18),
                  const _TipOfTheDay(),
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
  const _HomeNavBar({required this.topInset, required this.trailing});

  final double topInset;
  final Widget trailing;

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
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF3D6FFF), Color(0xFF00C2CB)],
                  ).createShader(bounds),
                  child: Text(
                    'ReplyWise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.05,
                    ),
                  ),
                ),
                Text(
                  'Your AI reply assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.helper.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
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
                left: 20,
                bottom: 14,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFEEF3FB)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.glassEdgeStrong,
                        width: 1,
                      ),
                      boxShadow: const [
                        // Deep ambient shadow.
                        BoxShadow(
                          color: Color(0x4D5C7DA8),
                          blurRadius: 26,
                          offset: Offset(0, 14),
                          spreadRadius: -4,
                        ),
                        // Tighter contact shadow.
                        BoxShadow(
                          color: Color(0x335C7DA8),
                          blurRadius: 9,
                          offset: Offset(0, 5),
                          spreadRadius: -3,
                        ),
                        // Top rim highlight.
                        BoxShadow(
                          color: Color(0xE6FFFFFF),
                          blurRadius: 1,
                          offset: Offset(0, -1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get started',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Color(0xFFE4ECF8)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.softNeutralShadow,
                              width: 1,
                            ),
                            boxShadow: const [
                              // Drop shadow for lift.
                              BoxShadow(
                                color: Color(0x405C7DA8),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                                spreadRadius: -1,
                              ),
                              // Top inner-rim highlight.
                              BoxShadow(
                                color: Color(0xF2FFFFFF),
                                blurRadius: 2,
                                offset: Offset(0, -1),
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primaryBlue,
                            size: 18,
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

/// A square grid cell for a primary feature: gradient app icon, chevron,
/// title, and a two-line description. Uses the feature's tinted glass surface.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    super.key,
    required this.imagePath,
    required this.feature,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String imagePath;
  final AppFeature feature;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;
    final accent = feature.accentColor;

    return Container(
      decoration: feature.glassCardDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Transform.scale(
                            scale: 1.08,
                            child: Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _chevron,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: accent,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.helper.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
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

/// "Recent" activity section. History is not stored yet, so this always shows
/// the empty state with a first-run call to action.
class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _CircleBadge(
                    icon: Icons.history_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nothing here yet', style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(
                          'Your recent replies, polished text, and '
                          'explanations will appear here.',
                          style: AppTextStyles.helper,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                  ),
                  onPressed: onCreate,
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Create your first reply'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Warm "Tip of the day" card. The tip rotates by day of month.
class _TipOfTheDay extends StatelessWidget {
  const _TipOfTheDay();

  static const _tips = <String>[
    'Keep emails under 120 words for higher response rates.',
    'Lead with your ask — put the key request in the first line.',
    "Match the other person's tone to build rapport faster.",
    'A clear subject line gets more replies than a clever one.',
    'Read your reply aloud once — it catches awkward phrasing.',
    'End with one clear next step so the reader knows what to do.',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];
    const amber = AppColors.guidanceColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.white, amber, 0.06)!,
            Color.lerp(Colors.white, amber, 0.18)!,
          ],
        ),
        border: Border.all(color: amber.withAlpha(45)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softBlueShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CircleBadge(
              icon: Icons.lightbulb_rounded,
              color: amber,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip of the day',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.guidanceDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(tip, style: AppTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small gradient circle with a white glyph, used as a leading badge.
class _CircleBadge extends StatelessWidget {
  const _CircleBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.white, 0.32)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(70),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
