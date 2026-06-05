import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/capsule/create_capsule_screen.dart';
import 'screens/capsule/open_capsule_screen.dart';
import 'screens/chat/matches_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (isSplash) return null;
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (c, s) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'capsule/create',
            builder: (c, s) => const CreateCapsuleScreen(),
          ),
          GoRoute(
            path: 'capsule/open/:id',
            builder: (c, s) => OpenCapsuleScreen(capsuleId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/matches', builder: (c, s) => const MatchesScreen()),
      GoRoute(
        path: '/chat/:matchId',
        builder: (c, s) => ChatScreen(matchId: s.pathParameters['matchId']!),
      ),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
    ],
  );
});
