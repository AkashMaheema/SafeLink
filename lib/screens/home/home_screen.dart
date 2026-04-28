import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../services/messaging_service.dart';
import '../../services/notification_overlay_service.dart';
import '../../widgets/alert_banner.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final MessagingService _messagingService;
  AlertModel? _activeAlert;

  /// Device location resolved once on init.
  AlertLocation? _deviceLocation;
  bool _isResolvingLocation = true;

  /// Fixed radius used to decide if the user is "near danger".
  static const double _nearbyRadiusKm = 5.0;

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

    // Listen for incoming emergency alerts.
    _messagingService = context.read<MessagingService>();
    _messagingService.onAlertReceived(_onAlertReceived);

    // Subscribe to emergency alerts topic
    _messagingService.subscribeToEmergencyAlerts();

    _loadDeviceLocation();
  }

  Future<void> _loadDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isResolvingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isResolvingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _deviceLocation = AlertLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _isResolvingLocation = false;
      });

      // Persist location for background FCM distance checks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('_last_device_lat', position.latitude);
      await prefs.setDouble('_last_device_lng', position.longitude);
    } catch (_) {
      if (mounted) setState(() => _isResolvingLocation = false);
    }
  }

  void _onAlertReceived(AlertModel alert) {
    if (!mounted) return;
    setState(() => _activeAlert = alert);
    NotificationOverlayService().showAlertOverlay(context, alert);
  }

  void _dismissAlert() {
    setState(() => _activeAlert = null);
    NotificationOverlayService().dismissOverlay();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messagingService.unsubscribeFromEmergencyAlerts();
    super.dispose();
  }

  // ── Nearby alert helpers ──────────────────────────────────────────────────

  AlertModel? _resolveNearestDanger(
    List<AlertModel> alerts,
    AlertLocation? loc,
  ) {
    if (alerts.isEmpty) return null;

    if (loc != null) {
      final maxMeters = _nearbyRadiusKm * 1000;
      final nearby = alerts.where((a) {
        return a.geoLocation.distanceTo(loc) <= maxMeters;
      }).toList();
      if (nearby.isEmpty) return null;
      nearby.sort((a, b) {
        final lvl = b.alertLevel.weight.compareTo(a.alertLevel.weight);
        if (lvl != 0) return lvl;
        return b.createdAt.compareTo(a.createdAt);
      });
      return nearby.first;
    }

    // No location — fall back to most critical red alert
    final reds = alerts.where((a) => a.alertLevel == AlertLevel.red).toList();
    if (reds.isEmpty) return null;
    reds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reds.first;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final alerts = context.watch<AlertProvider>().alerts;
    final userLocation = context.select<AlertProvider, AlertLocation?>(
      (p) => p.userLocation,
    );
    final activeLocation = _deviceLocation ?? userLocation;
    final nearestDanger = _resolveNearestDanger(alerts, activeLocation);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_activeAlert != null)
                AlertBanner(
                  alert: _activeAlert!,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.map),
                  onDismiss: _dismissAlert,
                ),
              _buildHeader(colorScheme),
              const SizedBox(height: 16),
              nearestDanger != null
                  ? _buildDangerStatusCard(nearestDanger)
                  : _buildSafeStatusCard(),
              const SizedBox(height: 24),
              _buildHelpText(colorScheme),
              const SizedBox(height: 16),
              _buildSosCircles(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI Components ────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme colorScheme) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.userModel?.displayName ?? 'User';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hey!',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              Text(
                userName,
                style: TextStyle(
                  color: colorScheme.onSurface,
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
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
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

  // ── Safe status card (blue gradient) ──────────────────────────────────────

  Widget _buildSafeStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0077B6), Color(0xFF03045E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isResolvingLocation
                        ? 'Checking nearby alerts…'
                        : 'All clear around you',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You\nare safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
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
            const SizedBox(width: 18),
            SizedBox(
              width: 140,
              height: 140,
              child: Image.asset('assets/images/img1.png', fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }

  // ── Danger status card (red gradient) ─────────────────────────────────────

  Widget _buildDangerStatusCard(AlertModel alert) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.alertDetail,
            arguments: alert,
          );
        },
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF2E2E), Color(0xFFB22E2E)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53030).withAlpha(51),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconForAlert(alert),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${alert.title} • ${_timeAgo(alert.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Danger\nnearby!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      alert.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText(ColorScheme colorScheme) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'Help is just a click away!\nClick ',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            children: const [
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

// ── Helpers ──────────────────────────────────────────────────────────────────

IconData _iconForAlert(AlertModel alert) {
  final t = alert.title.toLowerCase();
  if (t.contains('accident')) return Icons.car_crash_rounded;
  if (t.contains('fire')) return Icons.local_fire_department_rounded;
  if (t.contains('medical')) return Icons.medical_services_rounded;
  if (t.contains('flood')) return Icons.water_damage_rounded;
  if (t.contains('quake')) return Icons.terrain_rounded;
  if (t.contains('robbery')) return Icons.lock_open_rounded;
  if (t.contains('assault')) return Icons.report_problem_rounded;
  return Icons.crisis_alert_rounded;
}

String _timeAgo(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} hr ago';
  return '${diff.inDays} day ago';
}
