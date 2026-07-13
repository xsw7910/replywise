import 'package:flutter/material.dart';

import '../localization/localization_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_feature_theme.dart';
import '../theme/app_text_styles.dart';

class LabeledTextField extends StatefulWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.helperText,
    this.maxLines = 4,
    this.minLines,
    this.maxLength,
    this.feature,
    this.showHeader = true,
    this.showCounter = true,
    this.showClearButton = false,
    this.fieldActions,
    this.scrollController,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? helperText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final AppFeature? feature;
  final bool showHeader;
  final bool showCounter;

  /// Shows a small clear button pinned to the top-right corner of the field
  /// whenever the field is not empty. Tapping it clears [controller].
  final bool showClearButton;

  final Widget? fieldActions;
  final ScrollController? scrollController;

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.feature?.accentColor ?? AppColors.primaryBlue;
    final compactFieldActions =
        widget.fieldActions != null &&
        widget.maxLines == 1 &&
        !widget.showCounter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Text(widget.label, style: AppTextStyles.cardTitle),
          if (widget.helperText != null) ...[
            const SizedBox(height: 3),
            Text(widget.helperText!, style: AppTextStyles.helper),
          ],
          const SizedBox(height: 10),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(_focusNode.hasFocus ? 242 : 215),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: accent.withAlpha(30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              TextField(
                controller: widget.controller,
                scrollController: widget.scrollController,
                focusNode: _focusNode,
                minLines: widget.minLines ?? widget.maxLines,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  counterText: widget.showCounter ? null : '',
                  contentPadding: _contentPadding(),
                  focusedBorder: widget.feature == null
                      ? null
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accent, width: 2),
                        ),
                ),
              ),
              if (widget.fieldActions != null)
                if (compactFieldActions)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(child: widget.fieldActions!),
                  )
                else
                  Positioned(
                    right: 8,
                    bottom: widget.showCounter ? 28 : 8,
                    child: widget.fieldActions!,
                  ),
              // Clear button pinned to the top-right corner (not vertically
              // centered), visible only while the field has text.
              if (widget.showClearButton)
                Positioned(
                  right: 4,
                  top: 4,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: context.l10n.clear,
                            visualDensity: VisualDensity.compact,
                            color: accent,
                            onPressed: widget.controller.clear,
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Content padding combining the bottom-right action row inset with the
  /// top-right clear-button inset so typed text never runs under a button.
  EdgeInsets? _contentPadding() {
    final compactFieldActions =
        widget.fieldActions != null &&
        widget.maxLines == 1 &&
        !widget.showCounter;
    // Room for the top-right clear button on the first line.
    final right = widget.showClearButton ? 44.0 : 16.0;
    if (widget.fieldActions == null) {
      return widget.showClearButton
          ? EdgeInsets.fromLTRB(16, 14, right, 14)
          : null;
    }
    if (compactFieldActions) {
      return const EdgeInsets.fromLTRB(16, 12, 48, 12);
    }
    return EdgeInsets.fromLTRB(16, 14, right, widget.showCounter ? 72 : 54);
  }
}
