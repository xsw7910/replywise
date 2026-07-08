import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'features/app_status/application/app_status_controller.dart';
import 'features/guidance/data/guidance_library_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob is only supported on mobile. Initialize before runApp so the first
  // rewarded ad can preload immediately; failures must never block startup.
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Ads are non-essential; the app runs fine without them.
    }
  }

  final prefs = await SharedPreferences.getInstance();

  // Resolve the running app version for force/optional update checks. Reading
  // package info is cheap; fall back to the compile-time default on failure.
  var appVersion = AppConfig.appVersion;
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) appVersion = info.version;
  } catch (_) {
    // Keep the default; version comparison degrades gracefully.
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        guidanceLibraryRepositoryProvider.overrideWith(
          (ref) =>
              GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
        ),
        currentAppVersionProvider.overrideWithValue(appVersion),
      ],
      child: const ReplyWiseApp(),
    ),
  );
}
