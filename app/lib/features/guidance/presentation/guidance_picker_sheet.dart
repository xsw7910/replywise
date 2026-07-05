import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/guidance_library_controller.dart';
import '../domain/guidance_template.dart';
import 'guidance_localization.dart';

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
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.chooseGuidance,
                  style: AppTextStyles.sectionTitle,
                ),
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
                          _SectionHeader(
                            context.l10n.favorites,
                            Icons.star_rounded,
                            AppColors.primaryBlue,
                          ),
                          ...state.favorites.map(
                            (t) => _PickerTile(
                              template: t,
                              onSelected: onSelected,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _SectionHeader(
                          context.l10n.builtIn,
                          Icons.library_books_outlined,
                          AppColors.textSecondary,
                        ),
                        ...state.builtInTemplates
                            .where((t) => !t.isFavorite)
                            .map(
                              (t) => _PickerTile(
                                template: t,
                                onSelected: onSelected,
                              ),
                            ),
                        if (state.customTemplates.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SectionHeader(
                            context.l10n.myGuidance,
                            Icons.edit_note_rounded,
                            AppColors.textSecondary,
                          ),
                          ...state.customTemplates
                              .where((t) => !t.isFavorite)
                              .map(
                                (t) => _PickerTile(
                                  template: t,
                                  onSelected: onSelected,
                                ),
                              ),
                        ],
                      ],
                    ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.guidanceLibrary);
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: Text(context.l10n.manageLibrary),
                  ),
                ),
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
        Text(label, style: AppTextStyles.badge.copyWith(color: color)),
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
    title: Text(
      localizedGuidanceTitle(context, template),
      style: AppTextStyles.cardTitle,
    ),
    subtitle: Text(
      localizedGuidanceContent(context, template),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.helper,
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
      child: Text(context.l10n.use),
    ),
  );
}
