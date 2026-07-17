import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'polish_page_controller.g.dart';

/// In-memory, user-editable input/UI state for the Polish page.
///
/// Holds only plain values — never controllers or widget objects. The polished
/// result lives in [PolishController]; this notifier owns the inputs and UI
/// toggles so they survive route disposal while the process is alive.
class PolishPageState {
  const PolishPageState({
    this.draft = '',
    this.guidance = '',
    this.customTone = '',
    this.customAudience = '',
    this.extraInstruction = '',
    this.guidanceExpanded = false,
    this.moreOptionsExpanded = false,
    this.tone = 'Auto',
    this.audience = 'Auto',
    this.length = 'Same',
  });

  final String draft;
  final String guidance;
  final String customTone;
  final String customAudience;
  final String extraInstruction;
  final bool guidanceExpanded;
  final bool moreOptionsExpanded;
  final String tone;
  final String audience;
  final String length;

  PolishPageState copyWith({
    String? draft,
    String? guidance,
    String? customTone,
    String? customAudience,
    String? extraInstruction,
    bool? guidanceExpanded,
    bool? moreOptionsExpanded,
    String? tone,
    String? audience,
    String? length,
  }) {
    return PolishPageState(
      draft: draft ?? this.draft,
      guidance: guidance ?? this.guidance,
      customTone: customTone ?? this.customTone,
      customAudience: customAudience ?? this.customAudience,
      extraInstruction: extraInstruction ?? this.extraInstruction,
      guidanceExpanded: guidanceExpanded ?? this.guidanceExpanded,
      moreOptionsExpanded: moreOptionsExpanded ?? this.moreOptionsExpanded,
      tone: tone ?? this.tone,
      audience: audience ?? this.audience,
      length: length ?? this.length,
    );
  }
}

/// Kept alive for the whole process so the Polish inputs are not lost when the
/// page's route is disposed and later rebuilt. A full app restart resets it.
@Riverpod(keepAlive: true)
class PolishPageController extends _$PolishPageController {
  @override
  PolishPageState build() => const PolishPageState();

  void setDraft(String value) {
    if (state.draft != value) state = state.copyWith(draft: value);
  }

  void setGuidance(String value) {
    if (state.guidance != value) state = state.copyWith(guidance: value);
  }

  void setCustomTone(String value) {
    if (state.customTone != value) state = state.copyWith(customTone: value);
  }

  void setCustomAudience(String value) {
    if (state.customAudience != value) {
      state = state.copyWith(customAudience: value);
    }
  }

  void setExtraInstruction(String value) {
    if (state.extraInstruction != value) {
      state = state.copyWith(extraInstruction: value);
    }
  }

  void setGuidanceExpanded(bool value) {
    if (state.guidanceExpanded != value) {
      state = state.copyWith(guidanceExpanded: value);
    }
  }

  void toggleGuidanceExpanded() => setGuidanceExpanded(!state.guidanceExpanded);

  void setMoreOptionsExpanded(bool value) {
    if (state.moreOptionsExpanded != value) {
      state = state.copyWith(moreOptionsExpanded: value);
    }
  }

  void toggleMoreOptionsExpanded() =>
      setMoreOptionsExpanded(!state.moreOptionsExpanded);

  void setTone(String value) => state = state.copyWith(tone: value);

  void setAudience(String value) => state = state.copyWith(audience: value);

  void setLength(String value) => state = state.copyWith(length: value);
}
