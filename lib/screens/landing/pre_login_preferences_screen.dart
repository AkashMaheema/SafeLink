import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/auth_gate.dart';

class PreLoginPreferencesScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const PreLoginPreferencesScreen({super.key, required this.onGetStarted});

  @override
  State<PreLoginPreferencesScreen> createState() =>
      _PreLoginPreferencesScreenState();
}

class _PreLoginPreferencesScreenState extends State<PreLoginPreferencesScreen> {
  bool _voiceAssist = false;
  int _textSizeIndex = 1;

  double get _textScale {
    switch (_textSizeIndex) {
      case 0:
        return 0.92;
      case 2:
        return 1.16;
      default:
        return 1.0;
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    // Push AuthGate — it reactively shows LoginScreen or MainShell
    // depending on auth state, so Google Sign-In redirect works correctly.
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  Future<void> _learnMore() async {
    if (!mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetColors = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: sheetColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sheetColors.outlineVariant, width: 1.1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About SafeLink',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: sheetColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'These quick settings help you personalize text size, visibility, and voice support before you sign in.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.55,
                  color: sheetColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setTextSize(int index) {
    setState(() {
      _textSizeIndex = index;
    });
    context.read<ThemeProvider>().setLargerText(index == 2);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.height < 700;

    double scale(double value) => value * _textScale;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Safe',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? scale(28) : scale(32),
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? scale(28) : scale(32),
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: const Color(0xFFE02323),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SettingCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.text_fields_rounded,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text Size',
                            style: GoogleFonts.poppins(
                              fontSize: scale(14),
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Adjust readability',
                            style: GoogleFonts.poppins(
                              fontSize: scale(10),
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(3, (index) {
                        final isSelected = _textSizeIndex == index;
                        final double fontSize = index == 0
                            ? scale(11)
                            : index == 1
                            ? scale(13)
                            : scale(16);
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () => _setTextSize(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF121212)
                                    : colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF121212)
                                      : colorScheme.outlineVariant,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'A',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SettingCard(
                child: _SwitchPreferenceRow(
                  icon: Icons.mic_none_rounded,
                  title: 'Voice Assist',
                  subtitle: 'Text-to-speech & voice input',
                  value: _voiceAssist,
                  onChanged: (value) => setState(() => _voiceAssist = value),
                ),
              ),
              const SizedBox(height: 10),
              _SettingCard(
                child: _SwitchPreferenceRow(
                  icon: Icons.visibility_outlined,
                  title: 'High Contrast',
                  subtitle: 'Improved visibility',
                  value: themeProvider.isHighContrast,
                  onChanged: (value) {
                    context.read<ThemeProvider>().setHighContrast(value);
                  },
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _learnMore,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Learn More',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _finishOnboarding,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1026),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Get Started',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SwitchPreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchPreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.onSurface),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF83868D),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFC9CDD4),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
