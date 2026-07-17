import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/legal_urls.dart';
import '../../core/launch/external_url_launcher.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../app_status/application/app_status_controller.dart';

/// App "About" page, opened from Settings. Shows the app identity (icon, name,
/// short description, developer), links to the Privacy Policy and Terms of
/// Service, and the installed version at the bottom.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// Opens [url] with the shared external-link launcher. On failure the app's
  /// error UI (a SnackBar, matching Settings) is shown instead of crashing.
  Future<void> _openLink(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final opened = await ref.read(externalUrlLauncherProvider)(Uri.parse(url));
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenLink)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Reuse the existing package-info-backed providers (set from
    // PackageInfo.fromPlatform in main()), so the version is never hardcoded.
    final version = ref.watch(currentAppVersionProvider);
    final buildNumber = ref.watch(currentAppBuildNumberProvider);

    return AppPage(
      title: l10n.about,
      showBackButton: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          const SizedBox(height: 8),
          const Center(child: _AppIcon()),
          const SizedBox(height: 18),
          _AppName(),
          const SizedBox(height: 6),
          Center(
            child: Text(
              appDeveloperName,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                l10n.appDescription,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _InfoCard(
            children: [
              _LinkRow(
                key: const Key('about-privacy-row'),
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF377CF6),
                iconBackground: const Color(0xFFEAF2FF),
                label: l10n.privacyPolicy,
                onTap: () =>
                    _openLink(context, ref, kReplyWisePrivacyPolicyUrl),
              ),
              const _RowDivider(),
              _LinkRow(
                key: const Key('about-terms-row'),
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF12A966),
                iconBackground: const Color(0xFFEAF9F1),
                label: l10n.termsOfService,
                onTap: () =>
                    _openLink(context, ref, kReplyWiseTermsOfServiceUrl),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              // e.g. "Version 1.0.0 (40)". The word is localized; the version
              // name and build number come from package info.
              '${l10n.version} $version ($buildNumber)',
              key: const Key('about-version'),
              textAlign: TextAlign.center,
              style: AppTextStyles.helper.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.aboutCopyright,
              key: const Key('about-copyright'),
              textAlign: TextAlign.center,
              style: AppTextStyles.badge.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded, softly-shadowed app icon shown at the top of the page.
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softBlueShadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icons/app_icon.png',
        key: const Key('about-app-icon'),
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Brand name with the same blue→teal gradient used in the Home header.
class _AppName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF3D6FFF), Color(0xFF00C2CB)],
        ).createShader(bounds),
        child: Text(
          appBrandName,
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}

/// White rounded card that groups the legal rows — mirrors the Settings menu
/// group so the two pages read as one design.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(232),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1849619A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// A single tappable legal link row: icon panel, label, chevron.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline divider between rows, inset past the icon column.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 71, right: 14),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF5)),
    );
  }
}
