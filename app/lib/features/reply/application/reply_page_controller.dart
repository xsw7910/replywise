import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reply_page_controller.g.dart';

/// In-memory, user-editable input/UI state for the Reply page.
///
/// This holds only plain values (Strings, bools, enum-like tokens) — never
/// controllers, focus nodes, or other widget/lifecycle objects. The generated
/// result itself lives in [ReplyController]; this notifier owns the inputs the
/// user types and the small UI toggles so they survive route disposal and page
/// reconstruction while the process is alive.
class ReplyPageState {
  const ReplyPageState({
    this.incoming = '',
    this.guidance = '',
    this.customTone = '',
    this.customAudience = '',
    this.guidanceExpanded = false,
    this.moreOptionsExpanded = false,
    this.tone = 'Auto',
    this.audience = 'Auto',
    this.length = 'Medium',
    this.channel = 'Auto',
  });

  final String incoming;
  final String guidance;
  final String customTone;
  final String customAudience;
  final bool guidanceExpanded;
  final bool moreOptionsExpanded;
  final String tone;
  final String audience;
  final String length;
  final String channel;

  ReplyPageState copyWith({
    String? incoming,
    String? guidance,
    String? customTone,
    String? customAudience,
    bool? guidanceExpanded,
    bool? moreOptionsExpanded,
    String? tone,
    String? audience,
    String? length,
    String? channel,
  }) {
    return ReplyPageState(
      incoming: incoming ?? this.incoming,
      guidance: guidance ?? this.guidance,
      customTone: customTone ?? this.customTone,
      customAudience: customAudience ?? this.customAudience,
      guidanceExpanded: guidanceExpanded ?? this.guidanceExpanded,
      moreOptionsExpanded: moreOptionsExpanded ?? this.moreOptionsExpanded,
      tone: tone ?? this.tone,
      audience: audience ?? this.audience,
      length: length ?? this.length,
      channel: channel ?? this.channel,
    );
  }
}

/// Kept alive for the whole process so the Reply inputs are not lost when the
/// page's route is disposed and later rebuilt. A full app restart resets it.
@Riverpod(keepAlive: true)
class ReplyPageController extends _$ReplyPageController {
  @override
  ReplyPageState build() => const ReplyPageState();

  // Text setters are guarded so a redundant write (e.g. re-emitting the same
  // value from a controller listener) does not notify listeners or churn.
  void setIncoming(String value) {
    if (state.incoming != value) state = state.copyWith(incoming: value);
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

  void setChannel(String value) => state = state.copyWith(channel: value);
}
