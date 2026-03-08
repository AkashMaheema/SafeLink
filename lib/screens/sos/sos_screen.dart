import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _isSending = false;
  bool _sent = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    setState(() => _isSending = true);

    // TODO: integrate real SOS dispatch (Firestore + FCM)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSending = false;
        _sent = true;
      });
    }
  }

  void _reset() => setState(() => _sent = false);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status banner
                if (_sent)
                  _StatusBanner(
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    message: 'SOS alert sent!\nHelp is on the way.',
                    onDismiss: _reset,
                  )
                else ...[
                  Text(
                    'Press & hold the SOS button\nto send an emergency alert.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 52),

                  // Pulsing SOS button
                  ScaleTransition(
                    scale: _isSending || _sent
                        ? const AlwaysStoppedAnimation(1.0)
                        : _pulseAnim,
                    child: GestureDetector(
                      onLongPress: _isSending ? null : _triggerSOS,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.error,
                          boxShadow: [
                            BoxShadow(
                              color: cs.error.withAlpha(100),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: _isSending
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sos,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    'HOLD',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 13,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (user != null)
                    Text(
                      'Sending as: ${user.displayName}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: cs.outline),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback onDismiss;
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 80, color: color),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
        const SizedBox(height: 28),
        OutlinedButton(onPressed: onDismiss, child: const Text('Send Another')),
      ],
    );
  }
}
