import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_error.dart';
import '../data/reply_repository.dart';
import '../domain/reply_models.dart';

part 'reply_controller.g.dart';

class ReplyState {
  const ReplyState({this.isLoading = false, this.result, this.error});

  final bool isLoading;
  final ReplyResult? result;
  final String? error;
}

@riverpod
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
    } on ApiError catch (error) {
      state = ReplyState(result: state.result, error: error.message);
    } catch (_) {
      state = ReplyState(
        result: state.result,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  String? _validate(ReplyRequest request) {
    final incoming = request.incoming.trim();
    final guidance = request.guidance.trim();
    if (incoming.isEmpty) return 'Enter the message you received.';
    if (guidance.isEmpty) return 'Describe how you want to reply.';
    if (incoming.length > 4000) {
      return 'The message must be 4000 characters or less.';
    }
    if (guidance.length > 1000) {
      return 'Guidance must be 1000 characters or less.';
    }
    if ((request.audience.custom?.length ?? 0) > 500) {
      return 'Custom audience must be 500 characters or less.';
    }
    return null;
  }
}
