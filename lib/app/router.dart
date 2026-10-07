import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/prefs.dart';
import '../features/battery/battery_guide_screen.dart';
import '../features/home/apps_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/professional/winddown_screen.dart';
import '../features/stats/stats_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Read once: onboarding only decides the first screen.
  final hasMode = ref.read(userModeProvider) != null;
  return GoRouter(
    initialLocation: hasMode ? '/home' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/apps', builder: (_, __) => const AppsScreen()),
      GoRoute(
        path: '/winddown-apps',
        builder: (_, __) => const AppsScreen(windDown: true),
      ),
      GoRoute(path: '/winddown', builder: (_, __) => const WindDownScreen()),
      GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
      GoRoute(path: '/battery', builder: (_, __) => const BatteryGuideScreen()),
    ],
  );
});
