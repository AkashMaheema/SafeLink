import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../providers/alert_provider.dart';
import '../../models/alert_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // State is watched here, but currently just uses placeholder static content.
    // You can wire this up to make your UI dynamic later.
    context.watch<AlertProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea ensures UI doesn't overlap with the notch or status bar
      body: SafeArea(
        // Wrapping the column in a scroll view fixes your bottom overflow bug.
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildHelpText(),
              const SizedBox(height: 16), // A large gap to create visual space
              _buildSosCircles(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI Components ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey!',
                style: TextStyle(
                  color: Color(0xFF070707),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Nutan Khangar',
                style: TextStyle(
                  color: Color(0xFF070707),
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE02323),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0077B6), Color(0xFF03045E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        // I have removed the placeholder network image from here.
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Update: Checked 2 mins ago',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You\nare safe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'No emergencies reported nearby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return const Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'Help is just a click away!\nClick ',
            style: TextStyle(
              color: Color(0xFF424B5A),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            children: [
              TextSpan(
                text: 'SOS button',
                style: TextStyle(
                  color: Color(0xFFE02323),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' to call for help.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSosCircles(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final alpha = (40 + (_pulseController.value * 45)).round();

        return Transform.scale(
          scale: _pulseScale.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE02323).withAlpha(alpha),
                  blurRadius: 24,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.sos);
        },
        child: Container(
          width: 280,
          height: 280,
          decoration: const BoxDecoration(
            color: Color(0xFFFAE8E9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              color: Color(0xFFF9D2D2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: Color(0xFFF2A6A6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFE02323),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Alert card & Empty State (kept for intactness from your design) ──────────

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  static Color _levelColor(AlertLevel l, ColorScheme cs) => switch (l) {
    AlertLevel.green => Colors.green.shade600,
    AlertLevel.yellow => Colors.amber.shade700,
    AlertLevel.red => cs.error,
  };

  static IconData _levelIcon(AlertLevel l) => switch (l) {
    AlertLevel.green => Icons.check_circle_outline,
    AlertLevel.yellow => Icons.warning_amber_outlined,
    AlertLevel.red => Icons.crisis_alert,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _levelColor(alert.alertLevel, cs);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(80), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(_levelIcon(alert.alertLevel), color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (alert.verifiedByGovernment)
                        Tooltip(
                          message: 'Government verified',
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: cs.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Chip(
                        label: alert.alertLevel.value.toUpperCase(),
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: '${(alert.radius / 1000).toStringAsFixed(1)} km',
                        color: cs.secondary,
                        icon: Icons.radar,
                      ),
                    ],
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No active alerts in your area.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
