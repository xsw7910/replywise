import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/guidance_template.dart';

/// Holds a guidance template selected from the standalone Guidance Library
/// that should be applied to Reply or Polish after navigation.
///
/// The target screen consumes the value (appends/fills its guidance field) and
/// immediately clears it so it is applied exactly once.
final pendingGuidanceProvider =
    NotifierProvider<PendingGuidanceController, GuidanceTemplate?>(
        PendingGuidanceController.new);

class PendingGuidanceController extends Notifier<GuidanceTemplate?> {
  @override
  GuidanceTemplate? build() => null;

  void set(GuidanceTemplate template) => state = template;

  /// Returns the pending template (if any) and clears it so it is used once.
  GuidanceTemplate? take() {
    final current = state;
    if (current != null) state = null;
    return current;
  }
}
