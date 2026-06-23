import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/guidance_library_controller.dart';
import '../domain/guidance_template.dart';

/// Full-screen bottom sheet for picking a guidance item.
/// Calls [onSelected] with the chosen template and pops itself.
class GuidancePickerSheet extends ConsumerWidget {
  const GuidancePickerSheet({super.key, required this.onSelected});

  final ValueChanged<GuidanceTemplate> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guidanceLibraryControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Guidance Library',
                        style: AppTextStyles.headlineMedium),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.guidanceLibrary);
                    },
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        if (state.favorites.isNotEmpty) ...[
                          _SectionHeader('Favorites',
                              Icons.star_rounded, AppColors.primary),
                          ...state.favorites.map((t) => _PickerTile(
                              template: t, onSelected: onSelected)),
                          const SizedBox(height: 8),
                        ],
                        _SectionHeader('Built-in',
                            Icons.library_books_outlined,
                            AppColors.textSecondary),
                        ...state.builtInTemplates
                            .where((t) => !t.isFavorite)
                            .map((t) =>
                                _PickerTile(template: t, onSelected: onSelected)),
                        if (state.customTemplates.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SectionHeader('My Guidance',
                              Icons.edit_note_rounded,
                              AppColors.textSecondary),
                          ...state.customTemplates
                              .where((t) => !t.isFavorite)
                              .map((t) => _PickerTile(
                                  template: t, onSelected: onSelected)),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(color: color)),
          ],
        ),
      );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.template, required this.onSelected});

  final GuidanceTemplate template;
  final ValueChanged<GuidanceTemplate> onSelected;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(template.title, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          template.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium,
        ),
        trailing: FilledButton.tonal(
          onPressed: () {
            Navigator.pop(context);
            onSelected(template);
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Use'),
        ),
      );
}
