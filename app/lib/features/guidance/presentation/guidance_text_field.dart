import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_feature_theme.dart';
import '../../../core/widgets/labeled_text_field.dart';

/// Shared guidance editor used by Reply and Polish.
///
/// Its compact action row is overlaid at the bottom-right by
/// [LabeledTextField], leaving enough bottom padding to prevent text overlap.
class GuidanceTextField extends StatelessWidget {
  const GuidanceTextField({
    super.key,
    required this.controller,
    required this.feature,
    required this.hintText,
    required this.maxLength,
    required this.onOpenLibrary,
    this.maxLines = 4,
  });

  final TextEditingController controller;
  final AppFeature feature;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final VoidCallback onOpenLibrary;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    // Preserve the existing Reply behavior: Paste replaces the current
    // guidance, caps it to the shared limit, and leaves the cursor at the end.
    controller.text = text.length > maxLength
        ? text.substring(0, maxLength)
        : text;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = feature.accentColor;
    return LabeledTextField(
      label: 'Guidance',
      feature: feature,
      showHeader: false,
      showCounter: false,
      controller: controller,
      hintText: hintText,
      maxLines: maxLines,
      maxLength: maxLength,
      fieldActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Guidance Library',
            visualDensity: VisualDensity.compact,
            color: accent,
            onPressed: onOpenLibrary,
            icon: const Icon(Icons.menu_book_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Paste',
            visualDensity: VisualDensity.compact,
            color: accent,
            onPressed: _paste,
            icon: const Icon(Icons.content_paste_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Clear',
            visualDensity: VisualDensity.compact,
            color: accent,
            onPressed: controller.clear,
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}
