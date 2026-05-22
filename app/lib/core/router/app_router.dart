import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/camera/camera_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/history/translation_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'camera', builder: (_, __) => const CameraScreen()),
          GoRoute(
            path: 'history',
            builder: (_, __) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (ctx, state) => TranslationDetailScreen(
                  entryId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
