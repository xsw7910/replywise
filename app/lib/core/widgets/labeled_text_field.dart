import 'package:flutter/material.dart';

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
                  contentPadding: widget.fieldActions == null
                      ? null
                      : compactFieldActions
                      ? const EdgeInsets.fromLTRB(16, 12, 48, 12)
                      : EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          widget.showCounter ? 72 : 54,
                        ),
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
            ],
          ),
        ),
      ],
    );
  }
}
