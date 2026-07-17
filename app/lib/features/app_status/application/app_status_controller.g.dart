// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_status_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appStatusControllerHash() =>
    r'4136d4856738a829a9c8c984b00b6448d1eace77';

/// Holds the cached app status and owns all fetch/gate logic.
///
/// Kept alive for the whole session so the in-memory cache survives navigation.
/// Building the controller schedules a non-blocking startup fetch; the initial
/// UI is never delayed waiting for it.
///
/// Copied from [AppStatusController].
@ProviderFor(AppStatusController)
final appStatusControllerProvider =
    NotifierProvider<AppStatusController, AppStatusState>.internal(
      AppStatusController.new,
      name: r'appStatusControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appStatusControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AppStatusController = Notifier<AppStatusState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
