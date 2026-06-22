import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_error.dart';
import '../data/polish_repository.dart';
import '../domain/polish_models.dart';

part 'polish_controller.g.dart';

class PolishState {
  const PolishState({this.isLoading = false, this.result, this.error});

  final bool isLoading;
  final PolishResult? result;
  final String? error;
}

@riverpod
class PolishController extends _$PolishController {
  @override
  PolishState build() => const PolishState();

  Future<void> polish(PolishRequest request) async {
    final validationError = _validate(request);
    if (validationError != null) {
      state = PolishState(result: state.result, error: validationError);
      return;
    }

    state = PolishState(isLoading: true, result: state.result);
    try {
      final result = await ref.read(polishRepositoryProvider).polish(request);
      state = PolishState(result: result);
    } on ApiError catch (error) {
      state = PolishState(result: state.result, error: error.message);
    } catch (_) {
      state = PolishState(
        result: state.result,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  String? _validate(PolishRequest request) {
    final draft = request.draft.trim();
    if (draft.isEmpty) return 'Enter an English draft to polish.';
    if (draft.length > 4000) {
      return 'The draft must be 4000 characters or less.';
    }
    if (request.direction == 'custom' &&
        (request.custom == null || request.custom!.trim().isEmpty)) {
      return 'Enter custom guidance.';
    }
    if ((request.custom?.length ?? 0) > 500) {
      return 'Custom guidance must be 500 characters or less.';
    }
    return null;
  }
}
