import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a draft handed to the Polish screen (e.g. "Use again" from a recent
/// item). Polish consumes and clears it on entry so the transfer happens once
/// and does not become sticky app state.
final pendingPolishInputProvider =
    NotifierProvider<PendingPolishInputController, String?>(
      PendingPolishInputController.new,
    );

class PendingPolishInputController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String draft) => state = draft;

  String? take() {
    final current = state;
    if (current != null) state = null;
    return current;
  }
}
