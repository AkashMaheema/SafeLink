import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_shell.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Named route constants — single source of truth for all routes.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home'; // → MainShell (tab 0)
  static const String sos = '/sos';
  static const String map = '/map';
  static const String profile = '/profile';
}

/// Centralised route generator passed to [MaterialApp.onGenerateRoute].
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _fade(const LoginScreen());
      case AppRoutes.register:
        return _fade(const RegisterScreen());
      case AppRoutes.home:
        return _fade(const MainShell());
      case AppRoutes.sos:
        return _fade(const SosScreen());
      case AppRoutes.map:
        return _fade(const MapScreen());
      case AppRoutes.profile:
        return _fade(const ProfileScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRoute<T> _fade<T>(Widget page) => PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );
}
