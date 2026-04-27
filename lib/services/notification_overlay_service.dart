import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class NotificationOverlayService {
  static final NotificationOverlayService _instance =
      NotificationOverlayService._internal();

  factory NotificationOverlayService() => _instance;

  NotificationOverlayService._internal();

  OverlayEntry? _currentEntry;

  /// Show a full-screen red blinking alert notification
  void showAlertOverlay(BuildContext context, AlertModel alert) {
    // Remove existing overlay if any
    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (_) =>
          _AlertOverlayWidget(alert: alert, onDismiss: () => dismissOverlay()),
    );

    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }

  /// Dismiss the current overlay
  void dismissOverlay() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _AlertOverlayWidget extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback onDismiss;

  const _AlertOverlayWidget({required this.alert, required this.onDismiss});

  @override
  State<_AlertOverlayWidget> createState() => _AlertOverlayWidgetState();
}

class _AlertOverlayWidgetState extends State<_AlertOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _slideController;

  Color get _dangerLineColor => Color.lerp(
    Colors.green.shade900,
    Colors.red.shade900,
    widget.alert.dangerLevel,
  )!;

  @override
  void initState() {
    super.initState();

    // Blink animation — alternates opacity
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Slide animation — slides banner up from bottom
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Auto-dismiss after 8 seconds
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _slideController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          final opacity = 0.5 + (_blinkController.value * 0.5);

          return Container(
            color: Colors.red.withValues(alpha: opacity * 0.3),
            child: child,
          );
        },
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_slideController),
          child: GestureDetector(
            onTap: () {}, // Prevent tap propagation to dismiss
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Red pulsing icon
                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      final scale = 0.9 + (_blinkController.value * 0.2);
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.warning_rounded,
                          size: 80,
                          color: Colors.red[700],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Alert title
                  Text(
                    '⚠ EMERGENCY ALERT',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red[800],
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Emergency type
                  Text(
                    widget.alert.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _dangerLineColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Text(
                    widget.alert.description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[700],
                        ),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.onDismiss();
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Tap to dismiss hint
                  Text(
                    'Tap anywhere to dismiss',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
