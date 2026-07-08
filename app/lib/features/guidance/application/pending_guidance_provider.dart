import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/guidance_template.dart';

enum GuidanceInsertionTarget {
  replyTone,
  replyAudience,
  polishTone,
  polishAudience,
}

class PendingTargetedGuidance {
  const PendingTargetedGuidance({required this.template, required this.target});

  final GuidanceTemplate template;
  final GuidanceInsertionTarget target;
}

/// Holds a guidance template selected from the standalone Guidance Library
/// that should be applied to Reply or Polish after navigation.
///
/// The target screen consumes the value (appends/fills its guidance field) and
/// immediately clears it so it is applied exactly once.
final pendingGuidanceProvider =
    NotifierProvider<PendingGuidanceController, GuidanceTemplate?>(
      PendingGuidanceController.new,
    );

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

final activeGuidanceInsertionTargetProvider =
    NotifierProvider<
      ActiveGuidanceInsertionTargetController,
      GuidanceInsertionTarget?
    >(ActiveGuidanceInsertionTargetController.new);

class ActiveGuidanceInsertionTargetController
    extends Notifier<GuidanceInsertionTarget?> {
  @override
  GuidanceInsertionTarget? build() => null;

  void set(GuidanceInsertionTarget target) => state = target;

  void clear() => state = null;
}

final pendingTargetedGuidanceProvider =
    NotifierProvider<
      PendingTargetedGuidanceController,
      PendingTargetedGuidance?
    >(PendingTargetedGuidanceController.new);

class PendingTargetedGuidanceController
    extends Notifier<PendingTargetedGuidance?> {
  @override
  PendingTargetedGuidance? build() => null;

  void set(GuidanceTemplate template, GuidanceInsertionTarget target) {
    state = PendingTargetedGuidance(template: template, target: target);
  }

  PendingTargetedGuidance? take() {
    final current = state;
    if (current != null) state = null;
    return current;
  }
}
