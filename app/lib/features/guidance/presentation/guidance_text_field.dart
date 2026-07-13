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
  late TextEditingValue _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.value;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GuidanceTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _lastValue = widget.controller.value;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  /// Scrolls to the end only for programmatic appends (Quick Guidance chips,
  /// templates, paste): the text grows by a whole snippet and the caret lands
  /// collapsed at the end. Single keystrokes, deletions, and cursor moves
  /// during manual editing never trigger a scroll, so the caret stays where
  /// the user is typing.
  void _onControllerChanged() {
    final previous = _lastValue;
    final current = widget.controller.value;
    _lastValue = current;

    final appendedSnippet = current.text.length >= previous.text.length + 2;
    final caretAtEnd =
        current.selection.isCollapsed &&
        current.selection.baseOffset == current.text.length;
    if (!appendedSnippet || !caretAtEnd) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    // Preserve the existing Reply behavior: Paste replaces the current
    // guidance, caps it to the shared limit, and leaves the cursor at the
    // end. One atomic value update: no intermediate text-without-selection
    // frame.
    final next = text.length > widget.maxLength
        ? text.substring(0, widget.maxLength)
        : text;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
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
      showClearButton: true,
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
        ],
      ),
    );
  }
}
