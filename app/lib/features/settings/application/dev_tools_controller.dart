import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../entitlement/usage_controller.dart';
import '../data/dev_tools_repository.dart';

final devToolsPanelVisibleProvider = Provider<bool>(
  (ref) => !kReleaseMode && (AppConfig.isDev || AppConfig.devToolsEnabled),
);

class DevToolsState {
  const DevToolsState({this.isLoading = false, this.message, this.error});

  final bool isLoading;
  final String? message;
  final String? error;
}

class DevToolsController extends Notifier<DevToolsState> {
  @override
  DevToolsState build() => const DevToolsState();

  Future<void> resetUsage() => _run(
    () => ref.read(devToolsRepositoryProvider).resetUsage(),
    'Free usage reset.',
  );

  Future<void> addCredits(int amount) => _run(
    () => ref.read(devToolsRepositoryProvider).addCredits(amount),
    'Credits added.',
  );

  Future<void> setPremium(bool isPremium) => _run(
    () => ref.read(devToolsRepositoryProvider).setPremium(isPremium),
    isPremium ? 'Premium simulation enabled.' : 'Premium simulation disabled.',
  );

  Future<void> refreshAccountState() => _run(
    () async {},
    'Account state refreshed.',
  );

  Future<void> _run(Future<void> Function() action, String message) async {
    if (state.isLoading) return;
    state = const DevToolsState(isLoading: true);
    try {
      await action();
      await ref.read(usageControllerProvider.notifier).refresh();
      state = DevToolsState(message: message);
    } catch (error) {
      state = DevToolsState(error: _message(error));
    }
  }

  String _message(Object error) {
    if (error is ApiError) {
      return error.displayMessage(fallback: error.message);
    }
    return 'Developer test action failed.';
  }
}

final devToolsControllerProvider =
    NotifierProvider<DevToolsController, DevToolsState>(
      DevToolsController.new,
    );
