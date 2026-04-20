import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/select_plan_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/plans/plans_screen.dart';
import '../../features/movie_detail/movie_detail_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuth = user != null;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register') ||
        state.matchedLocation.startsWith('/select-plan');

    if (!isAuth && !isAuthRoute) return '/login';
    if (isAuth && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/select-plan',
      builder: (_, state) {
        final extra = state.extra as Map<String, String>?;
        return SelectPlanScreen(
          name: extra?['name'] ?? '',
          email: extra?['email'] ?? '',
          password: extra?['password'] ?? '',
        );
      },
    ),
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (_, __, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
        GoRoute(path: '/plans', builder: (_, __) => const PlansScreen()),
      ],
    ),
    GoRoute(
      path: '/movie/:id',
      builder: (_, state) => MovieDetailScreen(
        movieId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
