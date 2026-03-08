import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import 'router.dart';

class SafeLinkApp extends StatelessWidget {
  const SafeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeLink',
      debugShowCheckedModeBanner: false,

      // ── Themes ──────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // respects device setting
      // ── Routing ─────────────────────────────────────────────────────────
      onGenerateRoute: AppRouter.onGenerateRoute,

      // ── Home: SplashScreen shows on startup, then navigates via AuthGate ─
      home: const SplashScreen(),
    );
  }
}
