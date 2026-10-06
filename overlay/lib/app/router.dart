import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/prefs.dart';
import '../features/home/apps_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Read once: onboarding only decides the first screen.
  final hasMode = ref.read(userModeProvider) != null;
  return GoRouter(
    initialLocation: hasMode ? '/home' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/apps', builder: (_, __) => const AppsScreen()),
    ],
  );
});
