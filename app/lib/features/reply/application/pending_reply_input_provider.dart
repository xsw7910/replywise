import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds an incoming message intentionally handed from Explain to Reply.
///
/// Reply consumes and clears this value on entry so the transfer happens once
/// and does not become sticky app state.
final pendingReplyInputProvider =
    NotifierProvider<PendingReplyInputController, String?>(
      PendingReplyInputController.new,
    );

class PendingReplyInputController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String message) => state = message;

  String? take() {
    final current = state;
    if (current != null) state = null;
    return current;
  }
}
