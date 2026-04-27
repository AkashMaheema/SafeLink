import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../services/alert_service.dart';

const Color _dangerRed = Color(0xFFE02323);

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final TextEditingController _briefController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(
    text: 'Pitipana, Homagama',
  );

  final List<_ProofItem> _proofItems = [];
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedEmergency;
  double _dangerLevel = 1.0;
  bool _isSending = false;
  LatLng? _selectedLatLng;

  Color get _dangerLineColor =>
      Color.lerp(Colors.green.shade900, Colors.red.shade900, _dangerLevel)!;

  AlertLevel get _alertLevelFromDanger {
    if (_dangerLevel >= 0.67) {
      return AlertLevel.red;
    }
    if (_dangerLevel >= 0.34) {
      return AlertLevel.yellow;
    }
    return AlertLevel.green;
  }

  String get _dangerLabel {
    if (_dangerLevel >= 0.67) {
      return 'High danger';
    }
    if (_dangerLevel >= 0.34) {
      return 'Medium danger';
    }
    return 'Low danger';
  }

  static const List<_EmergencyType> _emergencyTypes = [
    _EmergencyType('accident', 'Accident', Icons.warning_amber_rounded),
    _EmergencyType('fire', 'Fire', Icons.local_fire_department),
    _EmergencyType('medical', 'Medical', Icons.medical_services),
    _EmergencyType('flood', 'Flood', Icons.water_damage),
    _EmergencyType('quake', 'Quake', Icons.terrain),
    _EmergencyType('robbery', 'Robbery', Icons.lock_open),
    _EmergencyType('assault', 'Assault', Icons.report_problem),
    _EmergencyType('other', 'Other', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _briefController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationFromMap() async {
    final picked = await Navigator.of(context).push<_PickedLocation>(
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(initial: _selectedLatLng),
      ),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedLatLng = picked.latLng;
      _locationController.text = picked.label;
    });
  }

  Future<void> _attachCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location service is disabled. Please enable it first.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage('Location permission was denied.');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLatLng = LatLng(position.latitude, position.longitude);
      _locationController.text =
          'Current Location (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
    });

    _showMessage('Current location attached');
  }

  Future<void> _onProofTap(_ProofType type) async {
    switch (type) {
      case _ProofType.photo:
        await _showPhotoOptions();
        return;
      case _ProofType.video:
        await _showVideoOptions();
        return;
      case _ProofType.voice:
        await _showVoiceOptions();
        return;
    }
  }

  Future<void> _showPhotoOptions() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      builder: (_) => const _AttachmentOptionSheet(
        title: 'Add Photo',
        actions: [_AttachmentAction.takePhoto, _AttachmentAction.pickImageFile],
      ),
    );

    if (action == _AttachmentAction.takePhoto) {
      final file = await _imagePicker.pickImage(source: ImageSource.camera);
      if (file != null) {
        _addProofFromPath(_ProofType.photo, file.path);
      }
      return;
    }

    if (action == _AttachmentAction.pickImageFile) {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      final path = picked?.files.single.path;
      if (path != null) {
        _addProofFromPath(_ProofType.photo, path);
      }
    }
  }

  Future<void> _showVideoOptions() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      builder: (_) => const _AttachmentOptionSheet(
        title: 'Add Video',
        actions: [_AttachmentAction.takeVideo, _AttachmentAction.pickVideoFile],
      ),
    );

    if (action == _AttachmentAction.takeVideo) {
      final file = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (file != null) {
        _addProofFromPath(_ProofType.video, file.path);
      }
      return;
    }

    if (action == _AttachmentAction.pickVideoFile) {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.video,
      );
      final path = picked?.files.single.path;
      if (path != null) {
        _addProofFromPath(_ProofType.video, path);
      }
    }
  }

  Future<void> _showVoiceOptions() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      builder: (_) => const _AttachmentOptionSheet(
        title: 'Add Voice',
        actions: [
          _AttachmentAction.pickAudioFile,
          _AttachmentAction.recordVoice,
        ],
      ),
    );

    if (action == _AttachmentAction.pickAudioFile) {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.audio,
      );
      final path = picked?.files.single.path;
      if (path != null) {
        _addProofFromPath(_ProofType.voice, path);
      }
      return;
    }

    if (action == _AttachmentAction.recordVoice) {
      _showMessage(
        'Voice recording is not wired yet. You can browse audio now.',
      );
    }
  }

  void _addProofFromPath(_ProofType type, String path) {
    final item = _ProofItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      name: _basename(path),
      path: path,
    );

    setState(() => _proofItems.add(item));
    _showMessage('${type.label} attached');
  }

  void _removeProof(String id) {
    setState(() => _proofItems.removeWhere((p) => p.id == id));
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitAlert() async {
    if (_selectedEmergency == null) {
      _showMessage('Select an emergency type first.');
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showMessage('Type location or attach map/current location.');
      return;
    }

    if (_briefController.text.trim().isEmpty) {
      _showMessage('Please describe the emergency briefly.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        _showMessage('You must be logged in to send an alert.');
        setState(() => _isSending = false);
        return;
      }

      // Determine alert level from the user-selected danger marker.
      final alertLevel = _alertLevelFromDanger;

      // Create alert model
      final alert = AlertModel(
        id: '', // Will be generated by Firestore
        title: _emergencyTypes
            .firstWhere((t) => t.id == _selectedEmergency)
            .label,
        description: _briefController.text.trim(),
        alertLevel: alertLevel,
        dangerLevel: _dangerLevel,
        geoLocation: _selectedLatLng != null
            ? AlertLocation(
                latitude: _selectedLatLng!.latitude,
                longitude: _selectedLatLng!.longitude,
              )
            : const AlertLocation(latitude: 6.9271, longitude: 79.8612),
        radius: 5000, // 5km radius
        verifiedByGovernment: false,
        createdByUid: auth.currentUser!.uid,
        createdAt: DateTime.now(),
      );

      // Submit to Firestore
      final alertService = context.read<AlertService>();
      await alertService.createAlert(alert);
      if (mounted) {
        // Force-refresh the shared live stream so all screens reflect this alert immediately.
        context.read<AlertProvider>().startListeningAll();
      }

      // Note: In production, this would be handled by Cloud Functions.
      // We already subscribe to this topic on app launch in main.dart,
      // so there's no need to do it again here, which could hang the app.

      if (!mounted) {
        return;
      }

      setState(() => _isSending = false);

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Emergency alert sent (${_selectedEmergency!.toUpperCase()})',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset form after 1 second
      await Future<void>.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _selectedEmergency = null;
          _dangerLevel = 1.0;
          _briefController.clear();
          _locationController.text = 'Pitipana, Homagama';
          _selectedLatLng = null;
          _proofItems.clear();
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSending = false);
      if (e is FirebaseException && e.code == 'permission-denied') {
        _showMessage(
          'Failed to send alert: permission denied. Ensure Firestore rules are deployed and you are signed in.',
        );
        return;
      }
      _showMessage('Failed to send alert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Report Emergency',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Select Emergency Type',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emergencyTypes.map((type) {
                    final isSelected = _selectedEmergency == type.id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmergency = type.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 102,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _dangerRed.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _dangerRed
                                : const Color(0xFFE3E3E3),
                            width: isSelected ? 1.7 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              color: isSelected
                                  ? _dangerRed
                                  : const Color(0xFF4C4C4C),
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF212121),
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Mark Danger Level',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _dangerLineColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Slider(
                      value: _dangerLevel,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      activeColor: _dangerLineColor,
                      inactiveColor: const Color(0xFFE3E3E3),
                      onChanged: (value) {
                        setState(() => _dangerLevel = value);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // const Text(
                        //   'Dark Green',
                        //   style: TextStyle(
                        //     color: Color(0xFF2E7D32),
                        //     fontFamily: 'Poppins',
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        Text(
                          _dangerLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _dangerLineColor,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // const Text(
                        //   'Dark Red',
                        //   style: TextStyle(
                        //     color: Color(0xFFB71C1C),
                        //     fontFamily: 'Poppins',
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Location',
                child: Column(
                  children: [
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Type location address',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE9E9E9),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE9E9E9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _dangerRed,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickLocationFromMap,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Select on Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _dangerRed,
                              side: const BorderSide(color: _dangerRed),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _attachCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Use Current'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLatLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Lat: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Color(0xFF616161),
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Attach Proof',
                child: Column(
                  children: [
                    if (_proofItems.isNotEmpty)
                      ..._proofItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9E9E9)),
                          ),
                          child: Row(
                            children: [
                              Icon(item.type.icon, color: _dangerRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6A6A6A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _removeProof(item.id),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: _dangerRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    Row(
                      children: [
                        Expanded(
                          child: _ProofActionButton(
                            icon: Icons.photo_camera,
                            label: 'Photo',
                            onTap: () => _onProofTap(_ProofType.photo),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProofActionButton(
                            icon: Icons.videocam,
                            label: 'Video',
                            onTap: () => _onProofTap(_ProofType.video),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProofActionButton(
                            icon: Icons.keyboard_voice,
                            label: 'Voice',
                            onTap: () => _onProofTap(_ProofType.voice),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Specify Emergency In Brief',
                child: TextField(
                  controller: _briefController,
                  minLines: 4,
                  maxLines: 7,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened, risks, and urgency...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _dangerRed,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _dangerRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSending ? null : _submitAlert,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSending ? 'Sending...' : 'Send Alert',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF212121),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ProofActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProofActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Color(0xFFE9E9E9)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _dangerRed),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: _dangerRed,
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentOptionSheet extends StatelessWidget {
  final String title;
  final List<_AttachmentAction> actions;

  const _AttachmentOptionSheet({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...actions.map((action) {
            return ListTile(
              leading: Icon(action.icon),
              title: Text(action.label),
              onTap: () => Navigator.pop(context, action),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;

  const _LocationPickerScreen({this.initial});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);
  static const double _fallbackZoom = 13;

  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.initial ?? _fallbackCenter;
    final initialZoom = widget.initial == null ? _fallbackZoom : 15.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location on Map'),
        actions: [
          TextButton(
            onPressed: _picked == null
                ? null
                : () {
                    final picked = _picked!;
                    final label =
                        'Map Pin (${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)})';
                    Navigator.pop(
                      context,
                      _PickedLocation(latLng: picked, label: label),
                    );
                  },
            child: const Text('Done'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: (_, latLng) => setState(() => _picked = latLng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.safelink.safelink',
          ),
          MarkerLayer(
            markers: _picked == null
                ? const <Marker>[]
                : [
                    Marker(
                      point: _picked!,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.location_pin,
                        color: _dangerRed,
                        size: 30,
                      ),
                    ),
                  ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: FilledButton(
          onPressed: _picked == null
              ? null
              : () {
                  final picked = _picked!;
                  final label =
                      'Map Pin (${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)})';
                  Navigator.pop(
                    context,
                    _PickedLocation(latLng: picked, label: label),
                  );
                },
          style: FilledButton.styleFrom(backgroundColor: _dangerRed),
          child: const Text('Use Selected Location'),
        ),
      ),
    );
  }
}

class _EmergencyType {
  final String id;
  final String label;
  final IconData icon;

  const _EmergencyType(this.id, this.label, this.icon);
}

enum _ProofType {
  photo('Photo', Icons.photo_camera),
  video('Video', Icons.videocam),
  voice('Voice', Icons.keyboard_voice);

  final String label;
  final IconData icon;
  const _ProofType(this.label, this.icon);
}

class _ProofItem {
  final String id;
  final _ProofType type;
  final String name;
  final String path;

  const _ProofItem({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
  });
}

enum _AttachmentAction {
  takePhoto('Take Photo', Icons.photo_camera),
  pickImageFile('Browse Image', Icons.perm_media),
  takeVideo('Record Video', Icons.videocam),
  pickVideoFile('Browse Video', Icons.folder_open),
  pickAudioFile('Browse Audio', Icons.audio_file),
  recordVoice('Record Voice', Icons.mic);

  final String label;
  final IconData icon;
  const _AttachmentAction(this.label, this.icon);
}

class _PickedLocation {
  final LatLng latLng;
  final String label;

  const _PickedLocation({required this.latLng, required this.label});
}
