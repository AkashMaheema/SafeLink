import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _locationGranted = false;
  bool _mapReady = false;
  double _nearbyRadiusKm = 5;

  static const LatLng _defaultCenter = LatLng(6.8731, 79.9982);
  static const double _defaultZoom = 15.2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AlertProvider>().startListeningAll();
    });
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return;
      }
      setState(() => _locationGranted = false);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!mounted) {
      return;
    }

    setState(() => _locationGranted = granted);
    if (!granted) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (!mounted) {
      return;
    }

    setState(() => _currentPosition = position);
    _fitSelectedAreaToView();
  }

  LatLng get _mapCenter => _currentPosition == null
      ? _defaultCenter
      : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

  AlertLocation get _referenceLocation => AlertLocation(
    latitude: _mapCenter.latitude,
    longitude: _mapCenter.longitude,
  );

  double _distanceToAlert(AlertModel alert) =>
      _referenceLocation.distanceTo(alert.geoLocation);

  String _radiusLabel(double radiusKm) {
    return radiusKm.toStringAsFixed(
      radiusKm.truncateToDouble() == radiusKm ? 0 : 1,
    );
  }

  List<Marker> _buildMarkers(List<AlertModel> alerts) {
    return alerts.take(20).map((alert) {
      final color = switch (alert.alertLevel) {
        AlertLevel.red => const Color(0xFFE84C4C),
        AlertLevel.yellow => const Color(0xFFD0AF1D),
        AlertLevel.green => const Color(0xFF47B36B),
      };

      return Marker(
        point: LatLng(alert.geoLocation.latitude, alert.geoLocation.longitude),
        width: 22,
        height: 22,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _centerOnUser() async {
    if (_currentPosition == null) {
      await _loadLocation();
      return;
    }
    _fitSelectedAreaToView();
  }

  void _fitSelectedAreaToView() {
    if (!_mapReady) {
      return;
    }

    final center = _mapCenter;
    final radiusMeters = _nearbyRadiusKm * 1000;
    final latDelta = radiusMeters / 111320.0;
    final lngDivider = (111320.0 * math.cos(center.latitude * math.pi / 180))
        .abs()
        .clamp(20000.0, 111320.0);
    final lngDelta = radiusMeters / lngDivider;

    final bounds = LatLngBounds(
      LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(22),
        maxZoom: _defaultZoom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alertProvider = context.watch<AlertProvider>();
    final alerts = alertProvider.alerts.toList();

    final nearbyAlerts = alerts
        .where((alert) => _distanceToAlert(alert) <= _nearbyRadiusKm * 1000)
        .toList();
    final mapAlerts = nearbyAlerts.isNotEmpty ? nearbyAlerts : alerts;
    final cardAlerts = nearbyAlerts.isNotEmpty ? nearbyAlerts : alerts;

    // Priority: highest danger first, then nearest, then newest.
    cardAlerts.sort((a, b) {
      final byDanger = b.alertLevel.weight.compareTo(a.alertLevel.weight);
      if (byDanger != 0) {
        return byDanger;
      }
      final byDistance = _distanceToAlert(a).compareTo(_distanceToAlert(b));
      if (byDistance != 0) {
        return byDistance;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MapHeader(
                onNotificationTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
                onCenterTap: _centerOnUser,
              ),
              const SizedBox(height: 12),
              _MapPreview(
                center: _mapCenter,
                zoom: _defaultZoom,
                selectedRadiusMeters: _nearbyRadiusKm * 1000,
                markers: _buildMarkers(mapAlerts),
                locationGranted: _locationGranted,
                mapController: _mapController,
                onMapReady: () {
                  if (!_mapReady) {
                    setState(() => _mapReady = true);
                  }
                  _fitSelectedAreaToView();
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Select the area nearby you',
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: Color(0xFF111111),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Within ${_radiusLabel(_nearbyRadiusKm)} km',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: const Color(0xFFE84C4C),
                        inactiveTrackColor: const Color(0xFFE1E1E1),
                        thumbColor: const Color(0xFFE84C4C),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _nearbyRadiusKm,
                        min: 1,
                        max: 10,
                        divisions: 18,
                        onChanged: (value) {
                          setState(() => _nearbyRadiusKm = value);
                          _fitSelectedAreaToView();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: cardAlerts.isEmpty
                    ? Column(
                        children: [
                          if (alertProvider.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                alertProvider.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFE02323),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          const _EmptyNearbyCard(),
                        ],
                      )
                    : ListView.separated(
                        itemCount: cardAlerts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final alert = cardAlerts[index];
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.alertDetail,
                              arguments: alert,
                            ),
                            child: _NearbyAlertCard(
                              alert: alert,
                              distanceMeters: _distanceToAlert(alert),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final VoidCallback onCenterTap;

  const _MapHeader({
    required this.onNotificationTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onCenterTap,
          icon: const Icon(Icons.my_location_outlined, size: 22),
          color: colorScheme.onSurface,
          tooltip: 'Center map',
        ),
        Expanded(
          child: Text(
            'Map',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_none_rounded, size: 25),
          color: colorScheme.onSurface,
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final double selectedRadiusMeters;
  final List<Marker> markers;
  final bool locationGranted;
  final MapController mapController;
  final VoidCallback onMapReady;

  const _MapPreview({
    required this.center,
    required this.zoom,
    required this.selectedRadiusMeters,
    required this.markers,
    required this.locationGranted,
    required this.mapController,
    required this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 332,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            onMapReady: onMapReady,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.safelink.safelink',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: selectedRadiusMeters,
                  useRadiusInMeter: true,
                  borderStrokeWidth: 2,
                  borderColor: const Color(0xFFE84C4C),
                  color: const Color(0xFFE84C4C).withAlpha(30),
                ),
              ],
            ),
            MarkerLayer(markers: markers),
            if (locationGranted)
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 14,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E88FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NearbyAlertCard extends StatelessWidget {
  final AlertModel alert;
  final double distanceMeters;

  const _NearbyAlertCard({required this.alert, required this.distanceMeters});

  String _distanceLabel() {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String _timeAgoLabel() {
    final difference = DateTime.now().difference(alert.createdAt);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  Color _statusColor() {
    return switch (alert.alertLevel) {
      AlertLevel.red => const Color(0xFFBE1E1E),
      AlertLevel.yellow => const Color(0xFFD0AF1D),
      AlertLevel.green => const Color(0xFF47B36B),
    };
  }

  IconData _icon() {
    final title = alert.title.toLowerCase();
    if (title.contains('fire')) {
      return Icons.local_fire_department_outlined;
    }
    if (title.contains('accident') || title.contains('crash')) {
      return Icons.car_crash_outlined;
    }
    if (title.contains('flood') || title.contains('water')) {
      return Icons.water_drop_outlined;
    }
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFEF),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon(), size: 18, color: const Color(0xFFE84C4C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title.isEmpty ? 'Nearby incident' : alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_distanceLabel()} - ${_timeAgoLabel()}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _statusColor(),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNearbyCard extends StatelessWidget {
  const _EmptyNearbyCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'No incidents found in the selected radius.',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
