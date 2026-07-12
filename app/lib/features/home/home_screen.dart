import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_brand.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../entitlement/usage_controller.dart';
import '../reply/widgets/reply_status_badge.dart';
import '../recent/application/recent_providers.dart';
import '../recent/domain/recent_item.dart';
import '../recent/presentation/recent_item_row.dart';

const _homeHorizontalPadding = 20.0;
const _gridGap = 12.0;

const _chevron = AppColors.textDisabled;

/// One drop shadow shared by every Home card so they read consistently — a
/// little heavier than the default card shadow. Kept local to Home so other
/// screens' cards are unaffected.
const _kHomeCardShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x42496A9E),
    blurRadius: 34,
    offset: Offset(0, 16),
    spreadRadius: -6,
  ),
  BoxShadow(
    color: Color(0x24496A9E),
    blurRadius: 12,
    offset: Offset(0, 5),
    spreadRadius: -3,
  ),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final usage = ref.watch(usageControllerProvider).usage;

    return AppPage(
      title: context.l10n.home,
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
                premiumIconAsset: 'assets/icons/premium.png',
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
                            feature: AppFeature.reply,
                            title: context.l10n.reply,
                            subtitle: context.l10n.generateThoughtfulReplies,
                            onTap: () => context.go(AppRoutes.reply),
                          ),
                        ),
                        const SizedBox(width: _gridGap),
                        Expanded(
                          child: _FeatureCard(
                            key: const Key('home-feature-polish'),
                            feature: AppFeature.polish,
                            title: context.l10n.polish,
                            subtitle: context.l10n.makeWritingClear,
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
                            feature: AppFeature.explain,
                            title: context.l10n.explain,
                            subtitle: context.l10n.understandTone,
                            onTap: () => context.go(AppRoutes.explain),
                          ),
                        ),
                        const SizedBox(width: _gridGap),
                        Expanded(
                          child: _FeatureCard(
                            key: const Key('home-feature-guidance'),
                            feature: AppFeature.guidance,
                            title: context.l10n.templates,
                            subtitle: context.l10n.reuseInstructions,
                            onTap: () =>
                                context.push(AppRoutes.guidanceLibrary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _RecentSection(),
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
          // Tightly-cropped transparent bubble: renders larger than the padded
          // app_icon.png at the same slot size and can never be clipped.
          Image.asset(
            'assets/icons/app_icon_tight.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
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
                    appBrandName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.05,
                    ),
                  ),
                ),
                Text(
                  context.l10n.yourAiReplyAssistant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.helper.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
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
        boxShadow: _kHomeCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            // Match the hero artwork's native ratio (1906×705) so the image
            // fills the card exactly: no left/right crop, no top/bottom gaps,
            // and all four corners share the single ClipRRect radius.
            aspectRatio: 1906 / 705,
            child: Image.asset('assets/image/hero_card.png', fit: BoxFit.cover),
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
    required this.feature,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AppFeature feature;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;
    final accent = feature.accentColor;

    return Container(
      // Same gradient + border as glassCardDecoration, but the shared Home
      // shadow so every card matches.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: feature.cardGradient,
        border: Border.all(color: const Color(0xE0FFFFFF), width: 1.2),
        boxShadow: _kHomeCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Feature texture behind the content (Reply/Polish/Explain/Guidance).
            Positioned.fill(
              child: Image.asset(feature.backgroundImage, fit: BoxFit.cover),
            ),
            Material(
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
                                child: Image.asset(
                                  feature.iconImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle.copyWith(
                                color: accent,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.helper.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _chevron,
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Recent" activity section. Shows the latest two local recent items, or an
/// empty-state card with a first-run call to action when there are none.
class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestRecentItemsProvider);
    final items = latest.asData?.value ?? const <RecentItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.l10n.recent, style: AppTextStyles.sectionTitle),
            const Spacer(),
            if (items.isNotEmpty)
              TextButton(
                onPressed: () => context.push(AppRoutes.history),
                child: Text(context.l10n.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 12),
        latest.when(
          data: (items) => items.isEmpty
              ? _RecentEmpty(onCreate: () => context.go(AppRoutes.reply))
              : _RecentCard(
                  cardKey: const Key('home-recent-populated-card'),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.cardBorder),
                        RecentItemRow(
                          item: items[i],
                          onTap: () => openRecentItem(context, items[i]),
                        ),
                      ],
                    ],
                  ),
                ),
          loading: () => const _HomeCard(
            child: SizedBox(
              height: 96,
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          error: (_, _) =>
              _RecentEmpty(onCreate: () => context.go(AppRoutes.reply)),
        ),
      ],
    );
  }
}

/// Empty-state card shown when there is no recent activity.
class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _RecentCard(
      cardKey: const Key('home-recent-empty-card'),
      illustrationKey: const Key('home-recent-empty-illustration'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        context.l10n.nothingHereYet,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.recentEmptyMessage,
                        style: AppTextStyles.helper,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                backgroundColor: const Color(0xD9FFFFFF),
                side: const BorderSide(color: AppColors.primaryBlue),
              ),
              onPressed: onCreate,
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(context.l10n.createFirstReply),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared Recent card surface. The decorative illustration is reserved for
/// the empty state so it does not compete with real recent items.
class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.cardKey,
    this.illustrationKey,
    required this.child,
  });

  final Key cardKey;
  final Key? illustrationKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      key: cardKey,
      backgroundColor: AppColors.recentCardBackground,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (illustrationKey != null)
            Positioned(
              right: -4,
              top: -4,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.48,
                  child: Image.asset(
                    'assets/icons/recent.png',
                    key: illustrationKey,
                    width: 84,
                    height: 62,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Warm "Tip of the day" card. The tip rotates by day of month.
class _TipOfTheDay extends StatelessWidget {
  const _TipOfTheDay();

  @override
  Widget build(BuildContext context) {
    final tips = [
      context.l10n.tipShortEmails,
      context.l10n.tipLeadWithAsk,
      context.l10n.tipMatchTone,
      context.l10n.tipClearSubject,
      context.l10n.tipReadAloud,
      context.l10n.tipClearNextStep,
    ];
    final tip = tips[DateTime.now().day % tips.length];
    const amber = AppColors.guidanceColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.white, amber, 0.10)!,
            Color.lerp(Colors.white, amber, 0.24)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: amber.withAlpha(45)),
        boxShadow: _kHomeCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -4,
              top: 0,
              child: Opacity(
                opacity: 0.44,
                child: Image.asset(
                  'assets/icons/tip_of_the_day.png',
                  key: const Key('home-tip-illustration'),
                  width: 88,
                  height: 66,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
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
                          context.l10n.tipOfTheDay,
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
          ],
        ),
      ),
    );
  }
}

/// A plain white Home card carrying the shared [_kHomeCardShadow]. Mirrors the
/// default GlassCard look (white fill, soft border, 16px padding).
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.4),
        boxShadow: _kHomeCardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
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
