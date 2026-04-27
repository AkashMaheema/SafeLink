import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing/landing_screen.dart';
import '../widgets/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(LandingScreen.seenOnboardingKey) ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            hasSeenOnboarding ? const AuthGate() : const LandingScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.height < 680;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Safe',
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 52 : 64,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  TextSpan(
                    text: 'Link',
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 52 : 64,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: const Color(0xFFE02323),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Safety First',
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 16 : 20,
                height: 1.0,
                color: const Color(0xFF150502),
                letterSpacing: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
