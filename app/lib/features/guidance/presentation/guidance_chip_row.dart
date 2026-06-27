import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../application/guidance_library_controller.dart';
import '../domain/guidance_template.dart';
import 'guidance_picker_sheet.dart';

/// Quick guidance chips shown on Reply and Polish screens.
/// Shows up to 6 favourite/built-in chips plus a "Library" chip.
class GuidanceChipRow extends ConsumerWidget {
  const GuidanceChipRow({super.key, required this.onSelected, this.feature});

  final ValueChanged<GuidanceTemplate> onSelected;
  final AppFeature? feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guidanceLibraryControllerProvider);
    final quick = state.isLoading
        ? <GuidanceTemplate>[]
        : ref
              .read(guidanceLibraryControllerProvider.notifier)
              .getQuickTemplates()
              .take(6)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick guidance', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...quick.map(
              (t) => ActionChip(
                backgroundColor: feature?.selectedChipColor,
                side: const BorderSide(color: Color(0xCCFFFFFF)),
                avatar: t.isFavorite
                    ? Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: feature?.accentColor,
                      )
                    : Icon(
                        Icons.add_rounded,
                        size: 15,
                        color: feature?.accentColor,
                      ),
                label: Text(
                  t.title,
                  style: TextStyle(color: feature?.accentColor),
                ),
                onPressed: () => onSelected(t),
              ),
            ),
            ActionChip(
              backgroundColor: feature?.selectedChipColor,
              side: const BorderSide(color: Color(0xCCFFFFFF)),
              avatar: Icon(
                Icons.library_books_outlined,
                size: 15,
                color: feature?.accentColor,
              ),
              label: Text(
                'Library',
                style: TextStyle(color: feature?.accentColor),
              ),
              onPressed: () => _openPicker(context),
            ),
          ],
        ),
      ],
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet<GuidanceTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GuidancePickerSheet(onSelected: onSelected),
    );
  }
}
