import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/live_caption_overlay.dart';
import 'router.dart';

/// Global navigator key — used by NotificationService to push routes
/// from notification tap callbacks without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SafeLinkApp extends StatelessWidget {
  const SafeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'SafeLink',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // ── Themes ──────────────────────────────────────────────────────────
      theme: themeProvider.isHighContrast
          ? AppTheme.lightHighContrastTheme
          : AppTheme.lightTheme,
      darkTheme: themeProvider.isHighContrast
          ? AppTheme.darkHighContrastTheme
          : AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // ── Routing ─────────────────────────────────────────────────────────
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return LiveCaptionOverlay(
          child: MediaQuery(
            data: data.copyWith(
              textScaler: themeProvider.isLargerText
                  ? const TextScaler.linear(1.35)
                  : data.textScaler,
            ),
            child: child!,
          ),
        );
      },

      // ── Home: SplashScreen shows on startup, then navigates via AuthGate ─
      home: const SplashScreen(),
    );
  }
}

