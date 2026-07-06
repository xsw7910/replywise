import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
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
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        guidanceLibraryRepositoryProvider.overrideWith(
          (ref) => GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
        ),
      ],
      child: const ReplyWiseApp(),
    ),
  );
}
