import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'router.dart';

class SafeLinkApp extends StatelessWidget {
  const SafeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'SafeLink',
      debugShowCheckedModeBanner: false,

      // ── Themes ──────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // ── Routing ─────────────────────────────────────────────────────────
      onGenerateRoute: AppRouter.onGenerateRoute,

      // ── Home: SplashScreen shows on startup, then navigates via AuthGate ─
      home: const SplashScreen(),
    );
  }
}
