import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/account_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/streaks_screen.dart';

// Wraps Firebase Auth's stream as a Listenable so GoRouter re-evaluates its
// redirect whenever the auth state changes (sign in, sign out, delete).
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final router = GoRouter(
  initialLocation: '/',
  refreshListenable: _AuthChangeNotifier(),
  redirect: (BuildContext context, GoRouterState state) {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final location = state.matchedLocation;

    // Splash screen handles its own navigation after the delay
    if (location == '/') return null;

    if (!isAuthenticated && location != '/login') return '/login';
    if (isAuthenticated && location == '/login') return '/home';

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/streaks',
      name: 'streaks',
      builder: (context, state) => const StreaksScreen(),
    ),
  ],
);
