import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/glass_card.dart';
import '../application/guidance_library_controller.dart';
import '../application/pending_guidance_provider.dart';
import '../domain/guidance_template.dart';

const _kColor = AppColors.guidanceColor;
const _feature = AppFeature.guidance;

class GuidanceLibraryScreen extends ConsumerWidget {
  const GuidanceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guidanceLibraryControllerProvider);

    // Surface any persistence failure, then clear it so it shows once.
    ref.listen(guidanceLibraryControllerProvider.select((s) => s.error), (
      previous,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next)));
        ref.read(guidanceLibraryControllerProvider.notifier).clearError();
      }
    });

    return AppPage(
      title: 'Guidance Library',
      subtitle: 'Save and reuse your guidance.',
      headerImagePath: 'assets/icons/guidance.png',
      accentColor: _kColor,
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'New guidance',
          icon: const Icon(Icons.add_rounded),
          onPressed: () => context.push(AppRoutes.guidanceEdit),
        ),
      ],
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kColor))
          : _Body(state: state),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final GuidanceLibraryState state;

  @override
  Widget build(BuildContext context) {
    // Favorited items appear only under Favorites — not duplicated below.
    final builtIns = state.builtInTemplates
        .where((t) => !t.isFavorite)
        .toList();
    final customs = state.customTemplates.where((t) => !t.isFavorite).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        if (state.favorites.isNotEmpty) ...[
          _SectionLabel('Favorites', Icons.star_rounded, _kColor),
          const SizedBox(height: 8),
          ...state.favorites.map((t) => _GuidanceCard(template: t)),
          const SizedBox(height: 20),
        ],
        _SectionLabel(
          'Built-in',
          Icons.library_books_outlined,
          AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        ...builtIns.map((t) => _GuidanceCard(template: t)),
        const SizedBox(height: 20),
        _SectionLabel(
          'My Guidance',
          Icons.edit_note_rounded,
          AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        if (state.customTemplates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Create your own guidance to reuse it later.',
              style: AppTextStyles.body,
            ),
          )
        else
          ...customs.map((t) => _GuidanceCard(template: t)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _feature.primaryButtonColor,
          ),
          onPressed: () => context.push(AppRoutes.guidanceEdit),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Guidance'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.badge.copyWith(color: color)),
    ],
  );
}

class _GuidanceCard extends ConsumerWidget {
  const _GuidanceCard({required this.template});

  final GuidanceTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(guidanceLibraryControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        feature: _feature,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(template.title, style: AppTextStyles.cardTitle),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _feature.selectedChipColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    template.category.label,
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.guidanceDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              template.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
            Row(
              children: [
                IconButton(
                  tooltip: template.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  icon: Icon(
                    template.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: template.isFavorite ? _kColor : AppColors.textHint,
                  ),
                  onPressed: () => controller.toggleFavorite(template.id),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: _kColor),
                  onPressed: () => _showUseSheet(context, ref),
                  child: const Text('Use'),
                ),
                if (!template.isBuiltIn)
                  PopupMenuButton<_Action>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textHint,
                    ),
                    onSelected: (action) => _onAction(context, ref, action),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: _Action.edit, child: Text('Edit')),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Use "${template.title}"',
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: _kColor),
              title: const Text('Use in Reply'),
              onTap: () => _useIn(sheetContext, ref, AppRoutes.reply),
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_rounded, color: _kColor),
              title: const Text('Use in Polish'),
              onTap: () => _useIn(sheetContext, ref, AppRoutes.polish),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _useIn(BuildContext sheetContext, WidgetRef ref, String route) {
    ref.read(pendingGuidanceProvider.notifier).set(template);
    Navigator.pop(sheetContext);
    sheetContext.go(route);
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _Action action,
  ) async {
    switch (action) {
      case _Action.edit:
        context.push(AppRoutes.guidanceEdit, extra: template);
      case _Action.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this guidance?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(guidanceLibraryControllerProvider.notifier)
              .delete(template.id);
        }
    }
  }
}

enum _Action { edit, delete }
