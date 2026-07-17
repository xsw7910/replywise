import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'explain_page_controller.g.dart';

/// In-memory, user-editable input state for the Explain page.
///
/// Holds only the message the user typed. The explanation result lives in
/// [ExplainController]; this notifier owns the input so it survives route
/// disposal while the process is alive.
class ExplainPageState {
  const ExplainPageState({this.message = ''});

  final String message;

  ExplainPageState copyWith({String? message}) =>
      ExplainPageState(message: message ?? this.message);
}

/// Kept alive for the whole process so the Explain input is not lost when the
/// page's route is disposed and later rebuilt. A full app restart resets it.
@Riverpod(keepAlive: true)
class ExplainPageController extends _$ExplainPageController {
  @override
  ExplainPageState build() => const ExplainPageState();

  void setMessage(String value) {
    if (state.message != value) state = state.copyWith(message: value);
  }
}
