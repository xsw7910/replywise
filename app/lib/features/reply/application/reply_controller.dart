import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/input_limits.dart';
import '../../../core/network/api_error.dart';
import '../data/reply_repository.dart';
import '../domain/reply_models.dart';
import '../../entitlement/usage_controller.dart';

part 'reply_controller.g.dart';

class ReplyState {
  const ReplyState({
    this.isLoading = false,
    this.result,
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final ReplyResult? result;
  final String? error;
  final String? errorCode;
}

@Riverpod(keepAlive: true)
class ReplyController extends _$ReplyController {
  @override
  ReplyState build() => const ReplyState();

  Future<void> generate(ReplyRequest request) async {
    final validationError = _validate(request);
    if (validationError != null) {
      state = ReplyState(result: state.result, error: validationError);
      return;
    }

    state = ReplyState(isLoading: true, result: state.result);
    try {
      final result = await ref.read(replyRepositoryProvider).generate(request);
      state = ReplyState(result: result);
      await ref.read(usageControllerProvider.notifier).refresh();
    } on ApiError catch (error) {
      state = ReplyState(
        result: state.result,
        error: error.displayMessage(fallback: 'Unable to generate a reply.'),
        errorCode: error.code ?? 'NETWORK_ERROR',
      );
    } catch (_) {
      state = ReplyState(
        result: state.result,
        error: 'Something went wrong. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  String? _validate(ReplyRequest request) {
    final incoming = request.incoming.trim();
    final guidance = request.guidance.trim();
    if (incoming.isEmpty) return 'Enter the message you received.';
    if (incoming.length > 4000) {
      return 'The message must be 4000 characters or less.';
    }
    if (guidance.length > InputLimits.guidanceMaxLength) {
      return 'Guidance must be '
          '${InputLimits.guidanceMaxLength} characters or less.';
    }
    if ((request.audience.custom?.length ?? 0) > 500) {
      return 'Custom audience must be 500 characters or less.';
    }
    return null;
  }
}
