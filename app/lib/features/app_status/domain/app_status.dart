import 'dart:math' as math;

import '../../../core/theme/app_feature_theme.dart';

/// Remote-config snapshot returned by `GET /v1/app-status`.
///
/// Field names mirror the backend camelCase contract. Unknown/missing fields
/// fall back to safe defaults so a partial payload never breaks the client.
class AppStatus {
  const AppStatus({
    required this.appName,
    required this.platform,
    required this.maintenance,
    required this.maintenanceMessage,
    required this.minSupportedVersion,
    required this.minSupportedBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.forceUpdate,
    required this.updateMessage,
    required this.disabledFeatures,
    required this.supportEmail,
    required this.updatedAt,
  });

  final String appName;
  final String platform;
  final bool maintenance;
  final String maintenanceMessage;
  final String minSupportedVersion;
  final int minSupportedBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final bool forceUpdate;
  final String updateMessage;
  final List<String> disabledFeatures;
  final String supportEmail;
  final DateTime updatedAt;

  static const String _defaultVersion = '1.0.0';
  static const String _defaultSupportEmail = 'support@novaaistudio.ca';

  factory AppStatus.fromJson(Map<String, dynamic> json) => AppStatus(
    appName: json['appName'] as String? ?? 'replywise',
    platform: json['platform'] as String? ?? 'android',
    maintenance: json['maintenance'] as bool? ?? false,
    maintenanceMessage: json['maintenanceMessage'] as String? ?? '',
    minSupportedVersion:
        json['minSupportedVersion'] as String? ?? _defaultVersion,
    minSupportedBuildNumber: _parseBuildNumber(json['minSupportedBuildNumber']),
    latestVersion: json['latestVersion'] as String? ?? _defaultVersion,
    latestBuildNumber: _parseBuildNumber(json['latestBuildNumber']),
    forceUpdate: json['forceUpdate'] as bool? ?? false,
    updateMessage: json['updateMessage'] as String? ?? '',
    disabledFeatures:
        (json['disabledFeatures'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList(growable: false),
    supportEmail: json['supportEmail'] as String? ?? _defaultSupportEmail,
    updatedAt:
        DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'appName': appName,
    'platform': platform,
    'maintenance': maintenance,
    'maintenanceMessage': maintenanceMessage,
    'minSupportedVersion': minSupportedVersion,
    'minSupportedBuildNumber': minSupportedBuildNumber,
    'latestVersion': latestVersion,
    'latestBuildNumber': latestBuildNumber,
    'forceUpdate': forceUpdate,
    'updateMessage': updateMessage,
    'disabledFeatures': disabledFeatures,
    'supportEmail': supportEmail,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  /// True when [feature] is listed in [disabledFeatures] (case-insensitive).
  bool isFeatureDisabled(AppFeature feature) =>
      disabledFeatures.contains(feature.name.toLowerCase());

  /// True when the running version+build is older than the supported floor.
  /// Semantic version is compared first; equal version names (1.0.0+32 vs
  /// 1.0.0+33) fall back to the numeric build number.
  bool isBelowMinimum(String currentVersion, int currentBuildNumber) =>
      compareVersionAndBuild(
        currentVersion,
        currentBuildNumber,
        minSupportedVersion,
        minSupportedBuildNumber,
      ) <
      0;

  /// True when a force update is required: the backend flag is set AND the
  /// running version+build is below the supported floor. A build that is
  /// already at or above the floor is never blocked, and forceUpdate=false
  /// clears any previously blocking state.
  bool requiresForceUpdate(String currentVersion, int currentBuildNumber) =>
      forceUpdate && isBelowMinimum(currentVersion, currentBuildNumber);

  /// True when a newer version+build exists but updating is optional.
  bool hasOptionalUpdate(String currentVersion, int currentBuildNumber) =>
      !requiresForceUpdate(currentVersion, currentBuildNumber) &&
      compareVersionAndBuild(
            currentVersion,
            currentBuildNumber,
            latestVersion,
            latestBuildNumber,
          ) <
          0;
}

int _parseBuildNumber(Object? value) {
  if (value is int) return value >= 0 ? value : 0;
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed >= 0 ? parsed : 0;
}

/// Decision returned by [evaluateGate] describing whether an AI request may
/// proceed given the current cached [AppStatus].
enum AppStatusGate { allowed, maintenance, forceUpdate, featureDisabled }

/// Pure gate evaluation used before Reply / Polish / Explain requests.
///
/// A null [status] (nothing cached yet) resolves to [AppStatusGate.allowed] so
/// the very first request is never blocked while the background fetch is still
/// in flight — the post-request error path handles a truly unreachable server.
AppStatusGate evaluateGate({
  required AppStatus? status,
  required AppFeature feature,
  required String currentVersion,
  int currentBuildNumber = 0,
}) {
  if (status == null) return AppStatusGate.allowed;
  if (status.maintenance) return AppStatusGate.maintenance;
  if (status.requiresForceUpdate(currentVersion, currentBuildNumber)) {
    return AppStatusGate.forceUpdate;
  }
  if (status.isFeatureDisabled(feature)) return AppStatusGate.featureDisabled;
  return AppStatusGate.allowed;
}

/// Compares two dotted version strings (e.g. `1.2.0`).
///
/// Returns a negative number when [a] < [b], zero when equal, positive when
/// [a] > [b]. Non-numeric or build-suffixed segments (`1.0.0+29`, `1.0.0-rc1`)
/// are tolerated by reading the leading integer of each segment.
int compareVersions(String a, String b) {
  final pa = _parseVersion(a);
  final pb = _parseVersion(b);
  final length = math.max(pa.length, pb.length);
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

/// Compares version+build pairs: semantic version first, and only when the
/// version names are equal does the numeric build number break the tie. So
/// `1.0.1+1` is newer than `1.0.0+99`, and `1.0.0+32` is older than
/// `1.0.0+33`.
int compareVersionAndBuild(
  String versionA,
  int buildA,
  String versionB,
  int buildB,
) {
  final byVersion = compareVersions(versionA, versionB);
  if (byVersion != 0) return byVersion;
  return buildA.compareTo(buildB);
}

List<int> _parseVersion(String version) => version
    .split('.')
    .map((segment) {
      final head = segment.trim().split(RegExp(r'[-+]')).first;
      return int.tryParse(head) ?? 0;
    })
    .toList(growable: false);
