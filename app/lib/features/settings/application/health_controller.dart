import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/health_repository.dart';

part 'health_controller.g.dart';

@riverpod
class HealthController extends _$HealthController {
  @override
  Future<HealthResponse> build() => _fetch();

  Future<HealthResponse> _fetch() =>
      ref.read(healthRepositoryProvider).checkHealth();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(healthRepositoryProvider).checkHealth(),
    );
  }
}
