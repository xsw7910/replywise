import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'entitlement_state.dart';
import 'usage_repository.dart';

part 'usage_controller.g.dart';

class UsageViewState {
  const UsageViewState({
    this.usage = const EntitlementState.initial(),
    this.isLoading = false,
    this.error,
  });
  final EntitlementState usage;
  final bool isLoading;
  final String? error;
}

@Riverpod(keepAlive: true)
class UsageController extends _$UsageController {
  @override
  UsageViewState build() => const UsageViewState();

  Future<void> refresh() async {
    state = UsageViewState(usage: state.usage, isLoading: true);
    try {
      final usage = await ref.read(usageRepositoryProvider).fetch();
      state = UsageViewState(usage: usage);
    } catch (_) {
      state = UsageViewState(
        usage: state.usage,
        error: 'Unable to refresh remaining uses.',
      );
    }
  }
}
