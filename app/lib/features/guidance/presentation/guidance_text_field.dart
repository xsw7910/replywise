import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_feature_theme.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/labeled_text_field.dart';

/// Shared guidance editor used by Reply and Polish.
///
/// Its compact action row is overlaid at the bottom-right by
/// [LabeledTextField], leaving enough bottom padding to prevent text overlap.
class GuidanceTextField extends StatefulWidget {
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

  @override
  State<GuidanceTextField> createState() => _GuidanceTextFieldState();
}

class _GuidanceTextFieldState extends State<GuidanceTextField> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToEnd);
  }

  @override
  void didUpdateWidget(covariant GuidanceTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_scrollToEnd);
      widget.controller.addListener(_scrollToEnd);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToEnd);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    // Preserve the existing Reply behavior: Paste replaces the current
    // guidance, caps it to the shared limit, and leaves the cursor at the end.
    widget.controller.text = text.length > widget.maxLength
        ? text.substring(0, widget.maxLength)
        : text;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.feature.accentColor;
    return LabeledTextField(
      label: context.l10n.guidance,
      feature: widget.feature,
      showHeader: false,
      showCounter: false,
      controller: widget.controller,
      scrollController: _scrollController,
      hintText: widget.hintText,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      fieldActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.guidanceLibrary,
            visualDensity: VisualDensity.compact,
            color: accent,
            onPressed: widget.onOpenLibrary,
            icon: const Icon(Icons.menu_book_rounded, size: 20),
          ),
          IconButton(
            tooltip: context.l10n.paste,
            visualDensity: VisualDensity.compact,
            color: accent,
            onPressed: _paste,
            icon: const Icon(Icons.content_paste_rounded, size: 20),
          ),
          IconButton(
            tooltip: context.l10n.clear,
            visualDensity: VisualDensity.compact,
            color: accent,
            onPressed: widget.controller.clear,
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}
