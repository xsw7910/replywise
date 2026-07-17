import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/input_limits.dart';
import '../../../core/network/api_error.dart';
import '../../entitlement/usage_controller.dart';
import '../data/explain_repository.dart';
import '../domain/reply_models.dart';

part 'explain_controller.g.dart';

class ExplainState {
  const ExplainState({
    this.isLoading = false,
    this.result,
    this.error,
    this.errorCode,
  });

  final bool isLoading;

  /// The last successful explanation, retained across navigation so returning
  /// to the page shows it again without re-requesting.
  final ExplainResult? result;
  final String? error;
  final String? errorCode;
}

@Riverpod(keepAlive: true)
class ExplainController extends _$ExplainController {
  @override
  ExplainState build() => const ExplainState();

  Future<ExplainResult?> explain({
    required String text,
    required String explainLang,
    String? appLocale,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      state = ExplainState(
        result: state.result,
        error: 'Enter a message to explain.',
      );
      return null;
    }
    if (cleaned.length > InputLimits.explainMessageMaxLength) {
      state = ExplainState(
        result: state.result,
        error:
            'The message must be '
            '${InputLimits.explainMessageMaxLength} characters or less.',
      );
      return null;
    }

    state = ExplainState(isLoading: true, result: state.result);
    try {
      final result = await ref
          .read(explainRepositoryProvider)
          .explain(
            text: cleaned,
            explainLang: explainLang,
            appLocale: appLocale,
          );
      state = ExplainState(result: result);
      // Explain now consumes a credit: kick off the balance refresh right
      // away, exactly like Reply and Polish. Not awaited — the explanation
      // result must reach the screen even while the balance fetch is still in
      // flight, and UsageController.refresh() handles its own errors.
      unawaited(ref.read(usageControllerProvider.notifier).refresh());
      return result;
    } on ApiError catch (error) {
      state = ExplainState(
        result: state.result,
        error: error.displayMessage(
          fallback: 'Unable to explain this message.',
        ),
        errorCode: error.code ?? 'NETWORK_ERROR',
      );
    } catch (_) {
      state = ExplainState(
        result: state.result,
        error: 'Something went wrong. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
    return null;
  }
}
