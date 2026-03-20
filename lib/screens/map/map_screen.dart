import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/alert_provider.dart';
import '../../models/alert_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _locationGranted = false;

  // Default camera — Mumbai (update once live location is added)
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (mounted) {
      setState(() => _locationGranted = status.isGranted);
    }
  }

  Set<Marker> _buildMarkers(List<AlertModel> alerts, ColorScheme cs) {
    return alerts.map((alert) {
      final color = switch (alert.alertLevel) {
        AlertLevel.red => BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        AlertLevel.yellow => BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
        AlertLevel.green => BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      };

      return Marker(
        markerId: MarkerId(alert.id),
        position: LatLng(
          alert.geoLocation.latitude,
          alert.geoLocation.longitude,
        ),
        icon: color,
        infoWindow: InfoWindow(title: alert.title, snippet: alert.description),
      );
    }).toSet();
  }

  Set<Circle> _buildCircles(List<AlertModel> alerts, ColorScheme cs) {
    return alerts.map((alert) {
      final color = switch (alert.alertLevel) {
        AlertLevel.red => Colors.red,
        AlertLevel.yellow => Colors.amber,
        AlertLevel.green => Colors.green,
      };

      return Circle(
        circleId: CircleId('circle_${alert.id}'),
        center: LatLng(alert.geoLocation.latitude, alert.geoLocation.longitude),
        radius: alert.radius,
        strokeColor: color.withAlpha(200),
        strokeWidth: 2,
        fillColor: color.withAlpha(30),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final cs = Theme.of(context).colorScheme;
    final markers = _buildMarkers(alertProvider.alerts, cs);
    final circles = _buildCircles(alertProvider.alerts, cs);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Alert Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Centre on my location',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_defaultCamera),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultCamera,
            onMapCreated: (c) => _mapController = c,
            markers: markers,
            circles: circles,
            myLocationButtonEnabled: _locationGranted,
            myLocationEnabled: _locationGranted,
            zoomControlsEnabled: false,
          ),

          // Legend
          Positioned(bottom: 24, left: 16, child: _Legend()),

          // Alert count chip
          Positioned(
            top: 12,
            right: 16,
            child: Chip(
              avatar: const Icon(Icons.crisis_alert, size: 18),
              label: Text(
                '${markers.length} alert${markers.length == 1 ? '' : 's'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendRow(color: Colors.red, label: 'Critical'),
            const SizedBox(height: 6),
            _LegendRow(color: Colors.amber, label: 'Moderate'),
            const SizedBox(height: 6),
            _LegendRow(color: Colors.green, label: 'Low risk'),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
