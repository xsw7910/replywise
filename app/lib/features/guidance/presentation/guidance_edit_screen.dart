import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/input_limits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../application/guidance_library_controller.dart';
import '../domain/guidance_template.dart';
import 'guidance_localization.dart';

const _feature = AppFeature.guidance;
const _kColor = AppColors.guidanceColor;

class GuidanceEditScreen extends ConsumerStatefulWidget {
  const GuidanceEditScreen({super.key, this.existing});

  /// Non-null when editing an existing custom template.
  final GuidanceTemplate? existing;

  @override
  ConsumerState<GuidanceEditScreen> createState() => _GuidanceEditScreenState();
}

class _GuidanceEditScreenState extends ConsumerState<GuidanceEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late GuidanceCategory _category;
  String? _titleError;
  String? _contentError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existing?.content ?? '',
    );
    _category = widget.existing?.category ?? GuidanceCategory.custom;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    setState(() {
      _titleError = title.isEmpty
          ? 'Title cannot be empty.'
          : title.length > InputLimits.guidanceTitleMaxLength
          ? 'Title must be ${InputLimits.guidanceTitleMaxLength} '
                'characters or less.'
          : null;
      _contentError = content.isEmpty
          ? 'Guidance content cannot be empty.'
          : content.length > InputLimits.guidanceMaxLength
          ? 'Guidance must be ${InputLimits.guidanceMaxLength} '
                'characters or less.'
          : null;
    });
    return _titleError == null && _contentError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;
    setState(() => _isSaving = true);
    final controller = ref.read(guidanceLibraryControllerProvider.notifier);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final ok = widget.existing != null
        ? await controller.update(
            widget.existing!.copyWith(
              title: title,
              content: content,
              category: _category,
            ),
          )
        : await controller.add(
            title: title,
            content: content,
            category: _category,
          );

    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      // Persistence failed; keep the screen open and show why.
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveGuidance)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AppPage(
      title: isEditing ? context.l10n.editGuidance : context.l10n.newGuidance,
      accentColor: _kColor,
      showBackButton: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          GlassCard(
            feature: _feature,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledTextField(
                  label: context.l10n.titleLabel,
                  feature: _feature,
                  controller: _titleController,
                  hintText: context.l10n.guidanceTitleHint,
                  maxLines: 1,
                  maxLength: InputLimits.guidanceTitleMaxLength,
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _titleError!,
                    style: AppTextStyles.helper.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                LabeledTextField(
                  label: context.l10n.guidance,
                  feature: _feature,
                  controller: _contentController,
                  hintText: context.l10n.guidanceHint,
                  helperText: context.l10n.writeAnyLanguage,
                  maxLines: 5,
                  maxLength: InputLimits.guidanceMaxLength,
                ),
                if (_contentError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _contentError!,
                    style: AppTextStyles.helper.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(context.l10n.category, style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GuidanceCategory.values
                      .map(
                        (c) => ChoiceChip(
                          label: Text(
                            localizedGuidanceCategory(context, c),
                            style: TextStyle(
                              color: _category == c
                                  ? _kColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                          selected: _category == c,
                          selectedColor: _feature.selectedChipColor,
                          checkmarkColor: _kColor,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _feature.primaryButtonColor,
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEditing
                        ? context.l10n.saveChanges
                        : context.l10n.saveGuidance,
                  ),
          ),
        ],
      ),
    );
  }
}
