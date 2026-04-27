import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';

class SosTabScreen extends StatefulWidget {
  const SosTabScreen({super.key});

  @override
  State<SosTabScreen> createState() => _SosTabScreenState();
}

class _SosTabScreenState extends State<SosTabScreen> {
  bool _showOthers = true;
  double _distanceFilterKm = 1;
  AlertLocation? _deviceLocation;
  bool _isResolvingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceLocation();
  }

  Future<void> _loadDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isResolvingLocation = false);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isResolvingLocation = false);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _deviceLocation = AlertLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _isResolvingLocation = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertProvider>().alerts;
    final currentUserId = context.select<AuthProvider, String?>(
      (auth) => auth.userModel?.uid,
    );
    final userLocation = context.select<AlertProvider, AlertLocation?>(
      (provider) => provider.userLocation,
    );
    final activeLocation = _deviceLocation ?? userLocation;

    final nearbyAlerts = _resolveNearbyAlerts(
      alerts,
      activeLocation,
      _distanceFilterKm,
    );
    final nearbyAlert = nearbyAlerts.isEmpty ? null : nearbyAlerts.first;
    final othersAlerts = alerts
        .where(
          (alert) => currentUserId == null || alert.createdByUid != currentUserId,
        )
        .toList();
    final yourAlerts = alerts
        .where(
          (alert) => currentUserId != null && alert.createdByUid == currentUserId,
        )
        .toList();
    final sourceAlerts = _showOthers
        ? (othersAlerts.isEmpty ? _previewOthersAlerts : othersAlerts)
        : (yourAlerts.isEmpty ? _previewYourAlerts : yourAlerts);
    final selectedAlerts = _filterAlertsByDistance(
      sourceAlerts,
      activeLocation,
      _distanceFilterKm,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(title: 'Alerts', onBellTap: () {}),
              const SizedBox(height: 28),
              const _SectionTitle(),
              const SizedBox(height: 12),
              nearbyAlert != null
                  ? _DangerHeroCard(alert: nearbyAlert)
                  : const _SafeHeroCard(),
              const SizedBox(height: 28),
              _AudienceSwitch(
                showOthers: _showOthers,
                onChanged: (value) => setState(() => _showOthers = value),
              ),
              const SizedBox(height: 18),
              _DistanceRow(
                distanceKm: _distanceFilterKm,
                isResolvingLocation: _isResolvingLocation,
                hasLocation: activeLocation != null,
                onChanged: (value) {
                  setState(() => _distanceFilterKm = value);
                },
              ),
              const SizedBox(height: 18),
              if (selectedAlerts.isEmpty)
                _EmptyAlertList(
                  message: activeLocation == null
                      ? 'Enable location to filter nearby alerts by distance.'
                      : 'No alerts found within ${_distanceLabel(_distanceFilterKm)}.',
                )
              else
                ...selectedAlerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AlertListCard(alert: alert),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<AlertModel> _resolveNearbyAlerts(
    List<AlertModel> alerts,
    AlertLocation? userLocation,
    double distanceFilterKm,
  ) {
    if (alerts.isEmpty) {
      return const [];
    }

    if (userLocation != null) {
      final nearby = _filterAlertsByDistance(alerts, userLocation, distanceFilterKm);
      nearby.sort(_sortAlerts);
      return nearby;
    }

    final criticalFallback = alerts
        .where((alert) => alert.alertLevel == AlertLevel.red)
        .toList();
    criticalFallback.sort(_sortAlerts);
    return criticalFallback.take(1).toList();
  }

  int _sortAlerts(AlertModel a, AlertModel b) {
    final levelDiff = b.alertLevel.weight.compareTo(a.alertLevel.weight);
    if (levelDiff != 0) {
      return levelDiff;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  List<AlertModel> _filterAlertsByDistance(
    List<AlertModel> alerts,
    AlertLocation? userLocation,
    double distanceFilterKm,
  ) {
    if (userLocation == null) {
      return alerts;
    }

    final maxDistanceMeters = distanceFilterKm * 1000;
    final filtered = alerts.where((alert) {
      return alert.geoLocation.distanceTo(userLocation) <= maxDistanceMeters;
    }).toList();
    filtered.sort(_sortAlerts);
    return filtered;
  }
}

final List<AlertModel> _previewOthersAlerts = [
  AlertModel(
    id: 'preview-accident',
    title: 'Road Accident',
    description: 'The incident involved the vehicle MH 41 AK 6543, which was involved.',
    alertLevel: AlertLevel.yellow,
    geoLocation: const AlertLocation(latitude: 18.5074, longitude: 73.8077),
    radius: 1000,
    createdByUid: 'preview-other',
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  AlertModel(
    id: 'preview-flood',
    title: 'Flooding',
    description: 'Flooding reported, move to higher ground.',
    alertLevel: AlertLevel.red,
    geoLocation: const AlertLocation(latitude: 18.5074, longitude: 73.8077),
    radius: 1500,
    createdByUid: 'preview-other-2',
    createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
  ),
];

final List<AlertModel> _previewYourAlerts = [
  AlertModel(
    id: 'preview-your-report',
    title: 'Road Accident',
    description: 'Your submitted alert is still visible to nearby users.',
    alertLevel: AlertLevel.yellow,
    geoLocation: const AlertLocation(latitude: 18.5074, longitude: 73.8077),
    radius: 1000,
    createdByUid: 'preview-you',
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
  ),
];

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBellTap;

  const _Header({required this.title, required this.onBellTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 21,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onBellTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Near ',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(
            text: 'by',
            style: TextStyle(
              color: Color(0xFFE12626),
              fontSize: 24,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerHeroCard extends StatelessWidget {
  final AlertModel alert;

  const _DangerHeroCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF2E2E), Color(0xFFB22E2E)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53030).withValues(alpha: 0.20),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _InfoPill(
                  icon: Icons.location_on_outlined,
                  label: _radiusLabel(alert.radius),
                  textColor: colorScheme.onError,
                ),
                const SizedBox(width: 10),
                _InfoPill(
                  icon: Icons.access_time_rounded,
                  label: _timeAgo(alert.createdAt),
                  textColor: colorScheme.onError,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.crisis_alert_outlined,
                    color: Color(0xFFE12626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: colorScheme.onError.withValues(alpha: 0.30),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 39,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.map);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.sos);
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onError,
              ),
              child: const Text(
                'Report',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _radiusLabel(double radiusInMeters) {
    if (radiusInMeters <= 0) {
      return 'Nearby';
    }
    final radiusInKm = radiusInMeters / 1000;
    return '${radiusInKm.toStringAsFixed(1)} km';
  }

  static String _timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }
    return '${difference.inDays} day ago';
  }
}

class _SafeHeroCard extends StatelessWidget {
  const _SafeHeroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC8F1FF), Color(0xFF92D6FF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              'there are no alerts\nnear by yours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 39,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                'You are Safe',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 17,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _AudienceSwitch extends StatelessWidget {
  final bool showOthers;
  final ValueChanged<bool> onChanged;

  const _AudienceSwitch({required this.showOthers, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _AudienceChip(
          label: 'Reported By Others',
          selected: showOthers,
          onTap: () => onChanged(true),
        ),
        _AudienceChip(
          label: 'Reported By You',
          selected: !showOthers,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _AudienceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AudienceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DistanceRow extends StatelessWidget {
  final double distanceKm;
  final bool isResolvingLocation;
  final bool hasLocation;
  final ValueChanged<double> onChanged;

  const _DistanceRow({
    required this.distanceKm,
    required this.isResolvingLocation,
    required this.hasLocation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              'Within ${_distanceLabel(distanceKm)}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.outlineVariant,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: distanceKm,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        if (isResolvingLocation)
          Text(
            'Getting your location...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          )
        else if (!hasLocation)
          Text(
            'Location unavailable. Showing all alerts instead of distance-filtered results.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
      ],
    );
  }
}

class _AlertListCard extends StatelessWidget {
  final AlertModel alert;

  const _AlertListCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _locationLabel(alert),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _dotColor(alert.alertLevel),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForAlert(alert),
                  color: const Color(0xFFE12626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _locationLabel(AlertModel alert) {
    if (alert.id.startsWith('preview-')) {
      return 'Kothrud, Pune, 411038';
    }
    return 'Lat ${alert.geoLocation.latitude.toStringAsFixed(4)}, Lng ${alert.geoLocation.longitude.toStringAsFixed(4)}';
  }

  static Color _dotColor(AlertLevel level) {
    return switch (level) {
      AlertLevel.red => const Color(0xFFBC1B1B),
      AlertLevel.yellow => const Color(0xFFD7AA11),
      AlertLevel.green => const Color(0xFF2E9F5D),
    };
  }
}

class _EmptyAlertList extends StatelessWidget {
  final String message;

  const _EmptyAlertList({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

String _distanceLabel(double distanceKm) {
  if (distanceKm == distanceKm.roundToDouble()) {
    return '${distanceKm.toStringAsFixed(0)} km';
  }
  return '${distanceKm.toStringAsFixed(1)} km';
}

IconData _iconForAlert(AlertModel alert) {
  final title = alert.title.toLowerCase();
  if (title.contains('flood')) {
    return Icons.flood_outlined;
  }
  if (title.contains('accident')) {
    return Icons.car_crash_outlined;
  }
  if (title.contains('fire')) {
    return Icons.local_fire_department_outlined;
  }
  if (title.contains('medical')) {
    return Icons.medical_services_outlined;
  }
  if (title.contains('quake')) {
    return Icons.landscape_outlined;
  }
  return Icons.crisis_alert_outlined;
}
