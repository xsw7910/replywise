import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guidance_library_repository.dart';
import '../domain/guidance_template.dart';

class GuidanceLibraryState {
  const GuidanceLibraryState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  final List<GuidanceTemplate> templates;
  final bool isLoading;
  final String? error;

  List<GuidanceTemplate> get favorites =>
      templates.where((t) => t.isFavorite).toList();

  List<GuidanceTemplate> get builtInTemplates =>
      templates.where((t) => t.isBuiltIn).toList();

  List<GuidanceTemplate> get customTemplates =>
      templates.where((t) => !t.isBuiltIn).toList();

  GuidanceLibraryState copyWith({
    List<GuidanceTemplate>? templates,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GuidanceLibraryState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GuidanceLibraryController extends Notifier<GuidanceLibraryState> {
  @override
  GuidanceLibraryState build() => _computeState();

  GuidanceLibraryRepository get _repo =>
      ref.read(guidanceLibraryRepositoryProvider);

  GuidanceLibraryState _computeState() {
    try {
      return GuidanceLibraryState(templates: _repo.loadTemplates());
    } catch (_) {
      return const GuidanceLibraryState(
        error: 'Failed to load guidance library.',
      );
    }
  }

  /// Runs an awaited persistence [action], then refreshes state from storage.
  /// Returns true on success; on failure keeps current templates and sets
  /// [GuidanceLibraryState.error] without throwing.
  Future<bool> _mutate(
    Future<void> Function() action,
    String errorMessage,
  ) async {
    try {
      await action();
      state = GuidanceLibraryState(templates: _repo.loadTemplates());
      return true;
    } catch (_) {
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> add({
    required String title,
    required String content,
    required GuidanceCategory category,
  }) {
    return _mutate(
      () =>
          _repo.addTemplate(title: title, content: content, category: category),
      'Could not save this guidance. Please try again.',
    );
  }

  Future<bool> update(GuidanceTemplate template) {
    return _mutate(
      () => _repo.updateTemplate(template),
      'Could not update this guidance. Please try again.',
    );
  }

  Future<bool> delete(String id) {
    return _mutate(
      () => _repo.deleteTemplate(id),
      'Could not delete this guidance. Please try again.',
    );
  }

  Future<bool> toggleFavorite(String id) {
    return _mutate(
      () => _repo.toggleFavorite(id),
      'Could not update favorites. Please try again.',
    );
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  List<GuidanceTemplate> getQuickTemplates() => _repo.getQuickTemplates();
}

final guidanceLibraryControllerProvider =
    NotifierProvider<GuidanceLibraryController, GuidanceLibraryState>(
      GuidanceLibraryController.new,
    );
