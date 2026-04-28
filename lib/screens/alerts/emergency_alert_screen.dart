import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../models/alert_model.dart';
import '../../providers/settings_provider.dart';

const Color _dangerRed = Color(0xFFE02323);

/// Full-screen emergency alert that appears over everything —
/// matching the red gradient + pulsing icon + Respond/Ignore design.
class EmergencyAlertScreen extends StatefulWidget {
  final AlertModel alert;

  const EmergencyAlertScreen({super.key, required this.alert});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _iconPulseController;

  @override
  void initState() {
    super.initState();

    final theme = context.read<SettingsProvider>().sosAlertTheme;

    // Outer concentric rings pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Icon scale pulse
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Apply theme-specific effects
    if (theme == 'Loud Siren') {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      _startPeriodicVibration();
    } else if (theme == 'Silent Flash') {
      // No vibration, no sound
    } else if (theme == 'Vibrate Only') {
      HapticFeedback.heavyImpact();
      _startPeriodicVibration();
    } else {
      // Default
      HapticFeedback.heavyImpact();
      _startPeriodicVibration();
    }
  }

  void _startPeriodicVibration() async {
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _iconPulseController.dispose();
    super.dispose();
  }

  void _onRespond() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.alertDetail,
      arguments: widget.alert,
    );
  }

  void _onIgnore() {
    Navigator.of(context).pop();
  }

  IconData _iconForAlert() {
    final t = widget.alert.title.toLowerCase();
    if (t.contains('fire')) return Icons.local_fire_department_rounded;
    if (t.contains('accident')) return Icons.car_crash_rounded;
    if (t.contains('medical')) return Icons.medical_services_rounded;
    if (t.contains('flood')) return Icons.water_damage_rounded;
    if (t.contains('quake') || t.contains('earthquake')) {
      return Icons.terrain_rounded;
    }
    if (t.contains('robbery') || t.contains('theft')) {
      return Icons.lock_open_rounded;
    }
    if (t.contains('assault') || t.contains('attack')) {
      return Icons.report_problem_rounded;
    }
    return Icons.local_fire_department_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE02323),
                Color(0xFFB71C1C),
                Color(0xFF7A1010),
                Color(0xFF4A0A0A),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Background emergency icons pattern ──────────────
                _buildBackgroundPattern(),

                // ── Main content ────────────────────────────────────
                Column(
                  children: [
                    // Top label
                    const SizedBox(height: 20),
                    const Text(
                      'Emergency Alert',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),

                    // Center — pulsing circles + icon
                    const Spacer(),
                    _buildPulsingCircles(),
                    const Spacer(),

                    // ── Bottom buttons ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Respond button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _onRespond,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _dangerRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 8,
                                shadowColor: Colors.black26,
                              ),
                              child: const Text(
                                'Respond',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Ignore button
                          TextButton(
                            onPressed: _onIgnore,
                            child: const Text(
                              'Ignore',
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pulsing concentric circles with icon ────────────────────────────────

  Widget _buildPulsingCircles() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        // Outer rings expand/contract slightly
        final outerScale = 1.0 + (pulse * 0.06);
        final midScale = 1.0 + (pulse * 0.04);

        return Transform.scale(
          scale: outerScale,
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outermost ring
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
                // Middle ring
                Transform.scale(
                  scale: midScale / outerScale,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(25),
                    ),
                  ),
                ),
                // Inner glowing circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withAlpha(40),
                        Colors.white.withAlpha(15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
                // Center icon circle
                AnimatedBuilder(
                  animation: _iconPulseController,
                  builder: (context, child) {
                    final iconScale =
                        0.95 + (_iconPulseController.value * 0.1);
                    return Transform.scale(
                      scale: iconScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _dangerRed,
                          boxShadow: [
                            BoxShadow(
                              color: _dangerRed.withAlpha(100),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForAlert(),
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Background decorative icons ─────────────────────────────────────────

  Widget _buildBackgroundPattern() {
    const icons = [
      Icons.local_fire_department_outlined,
      Icons.warning_amber_rounded,
      Icons.medical_services_outlined,
      Icons.car_crash_outlined,
      Icons.water_damage_outlined,
      Icons.shield_outlined,
      Icons.phone_in_talk_outlined,
      Icons.location_on_outlined,
      Icons.crisis_alert_outlined,
      Icons.health_and_safety_outlined,
      Icons.local_hospital_outlined,
      Icons.add_alert_outlined,
    ];

    return Positioned.fill(
      child: Opacity(
        opacity: 0.06,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
          ),
          padding: const EdgeInsets.all(20),
          itemCount: 48,
          itemBuilder: (_, i) => Icon(
            icons[i % icons.length],
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
