import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';
import 'pre_login_preferences_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  static const seenOnboardingKey = 'has_seen_onboarding';

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_LandingPageData> _pages = const [
    _LandingPageData(
      titleBlack: 'Safe',
      titleRed: 'Link',
      heading: 'Welcome',
      description:
          'Welcome to SafeLink. Report accidents, disasters, and dangerous situations quickly and easily.',
      imagePath: 'assets/images/landingPageOne.png',
    ),
    _LandingPageData(
      titleBlack: 'Emergency ',
      titleRed: 'Alerts',
      heading: 'Stay Informed',
      description:
          'Receive real-time alerts about accidents, floods, and emergencies near you so you can act early and stay safe.',
      imagePath: 'assets/images/ladingPageTwo.png',
    ),
    _LandingPageData(
      titleBlack: 'Asking ',
      titleRed: 'Help',
      heading: 'Get Help Fast',
      description:
          'Request help instantly during accidents or disasters. SafeLink connects you with responders when you need it most.',
      imagePath: 'assets/images/landingPageThree.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishLanding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LandingScreen.seenOnboardingKey, true);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  void _skipToSetup() {
    _openSetupScreen();
  }

  void _openSetupScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            PreLoginPreferencesScreen(onGetStarted: _finishLanding),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex == _pages.length - 1) {
      _openSetupScreen();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text: page.titleBlack,
                                style: const TextStyle(
                                  color: Color(0xFF141414),
                                ),
                              ),
                              TextSpan(
                                text: page.titleRed,
                                style: const TextStyle(
                                  color: Color(0xFFE02323),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                page.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          page.heading,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.6,
                            color: const Color(0xFF4C4C4C),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skipToSetup,
                    child: Text(
                      'SKIP',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6E6E6E),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 16 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE02323)
                              : const Color(0xFFD0D0D0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentIndex == _pages.length - 1 ? 'SETUP' : 'NEXT',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingPageData {
  final String titleBlack;
  final String titleRed;
  final String heading;
  final String description;
  final String imagePath;

  const _LandingPageData({
    required this.titleBlack,
    required this.titleRed,
    required this.heading,
    required this.description,
    required this.imagePath,
  });
}
