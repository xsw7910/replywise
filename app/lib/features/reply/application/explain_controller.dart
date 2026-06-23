import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/input_limits.dart';
import '../../../core/network/api_error.dart';
import '../data/explain_repository.dart';
import '../domain/reply_models.dart';

part 'explain_controller.g.dart';

class ExplainState {
  const ExplainState({this.isLoading = false, this.error, this.errorCode});

  final bool isLoading;
  final String? error;
  final String? errorCode;
}

@riverpod
class ExplainController extends _$ExplainController {
  @override
  ExplainState build() => const ExplainState();

  Future<ExplainResult?> explain({
    required String text,
    required String explainLang,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      state = const ExplainState(error: 'Enter a message to explain.');
      return null;
    }
    if (cleaned.length > InputLimits.explainMessageMaxLength) {
      state = ExplainState(
        error:
            'The message must be '
            '${InputLimits.explainMessageMaxLength} characters or less.',
      );
      return null;
    }

    state = const ExplainState(isLoading: true);
    try {
      final result = await ref
          .read(explainRepositoryProvider)
          .explain(text: cleaned, explainLang: explainLang);
      state = const ExplainState();
      return result;
    } on ApiError catch (error) {
      state = ExplainState(
        error: error.displayMessage(
          fallback: 'Unable to explain this message.',
        ),
        errorCode: error.code ?? 'NETWORK_ERROR',
      );
    } catch (_) {
      state = const ExplainState(
        error: 'Something went wrong. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
    return null;
  }
}
