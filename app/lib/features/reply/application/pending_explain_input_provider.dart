import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a message handed to the Explain screen (e.g. "Use again" from a recent
/// item). Explain consumes and clears it on entry so the transfer happens once
/// and does not become sticky app state.
final pendingExplainInputProvider =
    NotifierProvider<PendingExplainInputController, String?>(
      PendingExplainInputController.new,
    );

class PendingExplainInputController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String message) => state = message;

  String? take() {
    final current = state;
    if (current != null) state = null;
    return current;
  }
}
