import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../models/alert_model.dart';
import '../../providers/settings_provider.dart';

const Color _dangerRed = Color(0xFFE02323);

class SetupSosScreen extends StatefulWidget {
  const SetupSosScreen({super.key});

  @override
  State<SetupSosScreen> createState() => _SetupSosScreenState();
}

class _SetupSosScreenState extends State<SetupSosScreen> {
  late double _radiusKm;
  late bool _sendLocation;
  late String _emergencyContact;
  late String _alertTheme;

  LatLng? _deviceLatLng;
  String _locationLabel = 'Resolving location…';
  bool _isResolvingLocation = true;

  static const List<String> _themeOptions = [
    'Default Theme',
    'Loud Siren',
    'Silent Flash',
    'Vibrate Only',
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _radiusKm = settings.sosAlertRadiusKm;
    _sendLocation = settings.sosSendLocation;
    _emergencyContact = settings.sosEmergencyContact;
    _alertTheme = settings.sosAlertTheme;
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationLabel = 'Location service disabled';
            _isResolvingLocation = false;
          });
        }
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationLabel = 'Location permission denied';
            _isResolvingLocation = false;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _deviceLatLng = LatLng(pos.latitude, pos.longitude);
        _locationLabel =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _isResolvingLocation = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationLabel = 'Could not resolve location';
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final settings = context.read<SettingsProvider>();
    await settings.setSosAlertRadiusKm(_radiusKm);
    await settings.setSosSendLocation(_sendLocation);
    await settings.setSosEmergencyContact(_emergencyContact);
    await settings.setSosAlertTheme(_alertTheme);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS settings saved')),
      );
      Navigator.of(context).pop();
    }
  }

  void _editContact() async {
    final controller = TextEditingController(text: _emergencyContact);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Emergency Contact',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Name or phone number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _emergencyContact = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setup SOS',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Distance slider ──────────────────────────────────
                    _buildRadiusSlider(colorScheme),
                    const SizedBox(height: 24),

                    // ── Location row ────────────────────────────────────
                    _buildLocationRow(colorScheme),
                    const SizedBox(height: 16),

                    // ── Map preview ─────────────────────────────────────
                    _buildMapPreview(colorScheme),
                    const SizedBox(height: 24),

                    // ── Send location toggle ────────────────────────────
                    _buildSendLocationToggle(colorScheme),
                    const SizedBox(height: 24),

                    // ── Select contact ───────────────────────────────────
                    _buildContactSection(colorScheme),
                    const SizedBox(height: 24),

                    // ── Select theme ─────────────────────────────────────
                    _buildThemeSection(colorScheme),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ─────────────────────────────────────────
            _buildBottomButtons(colorScheme),
          ],
        ),
      ),
    );
  }

  // ── Radius slider ─────────────────────────────────────────────────────────

  Widget _buildRadiusSlider(ColorScheme colorScheme) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: _dangerRed,
            inactiveTrackColor: colorScheme.outlineVariant,
            thumbColor: _dangerRed,
            overlayColor: _dangerRed.withAlpha(36),
            thumbShape: const _RadiusThumbShape(),
            valueIndicatorColor: _dangerRed,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: Slider(
            value: _radiusKm,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_radiusKm.round()} km',
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 km',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '100 km',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Location row ──────────────────────────────────────────────────────────

  Widget _buildLocationRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: colorScheme.onSurface),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _locationLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: _loadLocation,
          child: const Text(
            'Change',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: _dangerRed,
            ),
          ),
        ),
      ],
    );
  }

  // ── Map preview ───────────────────────────────────────────────────────────

  Widget _buildMapPreview(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: _deviceLatLng != null
            ? Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _deviceLatLng!,
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.safelink.safelink',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _deviceLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: _dangerRed,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // "You are here" label
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'You are here',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // "Track my location" link
                  Positioned(
                    bottom: 10,
                    right: 14,
                    child: GestureDetector(
                      onTap: _loadLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(230),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 13,
                              color: _dangerRed,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Track my location',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _dangerRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: _isResolvingLocation
                      ? const CircularProgressIndicator(color: _dangerRed)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _locationLabel,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
      ),
    );
  }

  // ── Send location toggle ──────────────────────────────────────────────────

  Widget _buildSendLocationToggle(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Send Current Location',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Switch(
          value: _sendLocation,
          onChanged: (v) => setState(() => _sendLocation = v),
          activeThumbColor: _dangerRed,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  // ── Contact section ───────────────────────────────────────────────────────

  Widget _buildContactSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Contact',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _emergencyContact.isEmpty
                      ? 'No contact selected'
                      : _emergencyContact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _emergencyContact.isEmpty
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _editContact,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: _dangerRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Theme section ─────────────────────────────────────────────────────────

  Widget _buildThemeSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Theme',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _alertTheme,
                    isExpanded: true,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    icon: const SizedBox.shrink(),
                    items: _themeOptions
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _alertTheme = v);
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final mockAlert = AlertModel(
                    id: 'test_alert',
                    title: 'Test Emergency',
                    description: 'This is a test of the full-screen emergency alert UI using the "$_alertTheme" theme.',
                    alertLevel: AlertLevel.red,
                    geoLocation: AlertLocation(latitude: 0, longitude: 0),
                    radius: 5.0,
                    createdByUid: 'system',
                    createdAt: DateTime.now(),
                  );
                  Navigator.of(context).pushNamed(
                    AppRoutes.emergencyAlert,
                    arguments: mockAlert,
                  );
                },
                child: const Text(
                  'Test',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: _dangerRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom buttons ────────────────────────────────────────────────────────

  Widget _buildBottomButtons(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: _dangerRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom rounded pill-shaped thumb with the km label above it.
class _RadiusThumbShape extends SliderComponentShape {
  const _RadiusThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(22, 22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Draw thumb circle
    canvas.drawCircle(
      center,
      10,
      Paint()..color = sliderTheme.thumbColor ?? _dangerRed,
    );

    // White inner dot
    canvas.drawCircle(
      center,
      4,
      Paint()..color = Colors.white,
    );
  }
}
