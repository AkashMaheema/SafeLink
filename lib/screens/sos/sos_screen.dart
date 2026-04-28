import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import '../../services/storage_service.dart';
import '../../app/router.dart';

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

  // Upload progress: null = not uploading, 0.0–1.0 = in progress
  double? _uploadProgress;
  String _uploadStatus = '';

  AlertLevel get _alertLevelFromDanger {
    if (_dangerLevel >= 0.67) {
      return AlertLevel.red;
    }
    if (_dangerLevel >= 0.34) {
      return AlertLevel.yellow;
    }
    return AlertLevel.green;
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
      final xfile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        _addProofItem(_ProofType.photo, xfile.name, bytes);
      }
      return;
    }

    if (action == _AttachmentAction.pickImageFile) {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        withData: true, // read bytes directly — handles content:// URIs
      );
      final pf = picked?.files.single;
      if (pf != null && pf.bytes != null) {
        _addProofItem(_ProofType.photo, pf.name, pf.bytes!);
      } else if (pf?.path != null) {
        // Fallback: real path available (desktop / some Android versions)
        final bytes = await File(pf!.path!).readAsBytes();
        _addProofItem(_ProofType.photo, pf.name, bytes);
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
      final xfile = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        _addProofItem(_ProofType.video, xfile.name, bytes);
      }
      return;
    }

    if (action == _AttachmentAction.pickVideoFile) {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.video,
        withData: true,
      );
      final pf = picked?.files.single;
      if (pf != null && pf.bytes != null) {
        _addProofItem(_ProofType.video, pf.name, pf.bytes!);
      } else if (pf?.path != null) {
        final bytes = await File(pf!.path!).readAsBytes();
        _addProofItem(_ProofType.video, pf.name, bytes);
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
        withData: true,
      );
      final pf = picked?.files.single;
      if (pf != null && pf.bytes != null) {
        _addProofItem(_ProofType.voice, pf.name, pf.bytes!);
      } else if (pf?.path != null) {
        final bytes = await File(pf!.path!).readAsBytes();
        _addProofItem(_ProofType.voice, pf.name, bytes);
      }
      return;
    }

    if (action == _AttachmentAction.recordVoice) {
      _showMessage(
        'Voice recording is not wired yet. You can browse audio now.',
      );
    }
  }

  void _addProofItem(_ProofType type, String name, Uint8List bytes) {
    final sizeMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
    final item = _ProofItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      name: name,
      sizeLabel: '$sizeMb MB',
      bytes: bytes,
    );
    setState(() => _proofItems.add(item));
    _showMessage('${type.label} attached ($sizeMb MB)');
  }

  void _removeProof(String id) {
    setState(() => _proofItems.removeWhere((p) => p.id == id));
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reviewAlert() async {
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

    // Build a local preview model — no Firestore write yet
    final previewAlert = AlertModel(
      id: 'preview-draft',
      title: _emergencyTypes
          .firstWhere((t) => t.id == _selectedEmergency)
          .label,
      description: _briefController.text.trim(),
      alertLevel: _alertLevelFromDanger,
      dangerLevel: _dangerLevel,
      geoLocation: _selectedLatLng != null
          ? AlertLocation(
              latitude: _selectedLatLng!.latitude,
              longitude: _selectedLatLng!.longitude,
            )
          : const AlertLocation(latitude: 6.9271, longitude: 79.8612),
      radius: 5000,
      verifiedByGovernment: false,
      createdByUid: '',
      createdAt: DateTime.now(),
      proofUrls: const [],
    );

    final photoItems = _proofItems
        .where((p) => p.type == _ProofType.photo)
        .toList();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AlertReviewScreen(
          alert: previewAlert,
          locationLabel: _locationController.text.trim(),
          photoItems: photoItems,
          onConfirm: _submitAlert,
        ),
      ),
    );
  }

  /// Performs the Firebase write and returns `true` on success.
  /// Does NOT navigate or show dialogs — the caller handles that.
  Future<bool> _submitAlert() async {
    // Capture providers BEFORE any async gaps — avoids
    // "Looking up a deactivated widget's ancestor" crashes.
    final alertService = context.read<AlertService>();
    final alertProvider = context.read<AlertProvider>();

    setState(() {
      _isSending = true;
      _uploadProgress = null;
      _uploadStatus = '';
    });

    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        _showMessage('You must be logged in to send an alert.');
        if (mounted) setState(() => _isSending = false);
        return false;
      }

      final alertLevel = _alertLevelFromDanger;

      // ── Step 1: Create the Firestore alert document ───────────────────────
      if (mounted) setState(() => _uploadStatus = 'Creating alert…');

      final alert = AlertModel(
        id: '',
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
        radius: 5000,
        verifiedByGovernment: false,
        createdByUid: auth.currentUser!.uid,
        createdAt: DateTime.now(),
        proofUrls: const [],
      );

      final alertId = await alertService.createAlert(alert);

      // ── Step 2: Save photo proofs as Base64 in Firestore subcollection ────
      final photoItems = _proofItems
          .where((p) => p.type == _ProofType.photo)
          .toList();

      if (photoItems.isNotEmpty) {
        final proofService = ProofStorageService();

        for (int i = 0; i < photoItems.length; i++) {
          final item = photoItems[i];

          if (mounted) {
            setState(() {
              _uploadStatus = 'Saving photo ${i + 1}/${photoItems.length}…';
              _uploadProgress = i / photoItems.length;
            });
          }

          try {
            await proofService.saveImageProof(
              alertId: alertId,
              bytes: item.bytes,
              fileName: item.name,
              onStatus: (s) {
                if (mounted) setState(() => _uploadStatus = s);
              },
            );
          } on FileTooLargeException catch (e) {
            _showMessage(e.message);
          }
        }

        if (mounted) setState(() => _uploadProgress = 1.0);
      }

      // Refresh alerts — provider was captured before async gaps
      alertProvider.startListeningAll();

      if (mounted) {
        setState(() {
          _isSending = false;
          _uploadProgress = null;
          _uploadStatus = '';
          // Reset form state
          _selectedEmergency = null;
          _dangerLevel = 1.0;
          _briefController.clear();
          _locationController.text = 'Pitipana, Homagama';
          _selectedLatLng = null;
          _proofItems.clear();
        });
      }

      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _uploadProgress = null;
          _uploadStatus = '';
        });
      }
      // Re-throw so the caller can display the error
      rethrow;
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
        title: const Text(
          'Report Emergency',
          style: TextStyle(
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
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _dangerRed
                                : colorScheme.outlineVariant,
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
                                color: colorScheme.onSurface,
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
                child: _DangerLevelSelector(
                  value: _dangerLevel,
                  onChanged: (v) => setState(() => _dangerLevel = v),
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
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
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
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
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
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      item.sizeLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
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
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
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
              // Upload progress indicator
              if (_isSending && _uploadProgress != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_uploadStatus.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _uploadStatus,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE3E3E3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  onPressed: _isSending ? null : _reviewAlert,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.preview_rounded),
                  label: Text(
                    _isSending
                        ? (_uploadStatus.isNotEmpty
                              ? _uploadStatus
                              : 'Sending…')
                        : 'Review Alert',
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

// ---------------------------------------------------------------------------
// Alert review screen — mirrors AlertDetailScreen layout, no Firestore yet
// ---------------------------------------------------------------------------

class _AlertReviewScreen extends StatefulWidget {
  final AlertModel alert;
  final String locationLabel;
  final List<_ProofItem> photoItems;
  final Future<bool> Function() onConfirm;

  const _AlertReviewScreen({
    required this.alert,
    required this.locationLabel,
    required this.photoItems,
    required this.onConfirm,
  });

  @override
  State<_AlertReviewScreen> createState() => _AlertReviewScreenState();
}

class _AlertReviewScreenState extends State<_AlertReviewScreen> {
  bool _isSending = false;

  IconData get _alertIcon {
    final t = widget.alert.title.toLowerCase();
    if (t.contains('accident')) return Icons.car_crash_rounded;
    if (t.contains('fire')) return Icons.local_fire_department_rounded;
    if (t.contains('medical')) return Icons.medical_services_rounded;
    if (t.contains('flood')) return Icons.water_damage_rounded;
    if (t.contains('quake')) return Icons.terrain_rounded;
    if (t.contains('robbery')) return Icons.lock_open_rounded;
    if (t.contains('assault')) return Icons.report_problem_rounded;
    return Icons.crisis_alert_rounded;
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    // Capture the navigator BEFORE the async call — the widget tree
    // will change during navigation so we must not touch `context` later.
    final nav = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final success = await widget.onConfirm();
      if (!mounted) return;
      if (success) {
        // Navigate to home, clearing the entire stack
        nav.pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      final msg = (e is FirebaseException && e.code == 'permission-denied')
          ? 'Permission denied. Check Firestore rules.'
          : e.toString();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Alert failed: $msg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alert = widget.alert;
    final isVerified = alert.verifiedByGovernment;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar — mirrors AlertDetailScreen
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Review Alert',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF57F17)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFF57F17),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Preview only — your alert has not been sent yet.',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF7A4F00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Verified badge area — mirrors _VerifiedBadge
                    Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE12626),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _alertIcon,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isVerified ? 'Verified' : 'Unverified',
                          style: TextStyle(
                            color: isVerified
                                ? const Color(0xFFE12626)
                                : Colors.orange,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Static neutral bar (no votes yet)
                        LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              Container(
                                height: 6,
                                width: constraints.maxWidth,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              Container(
                                height: 6,
                                width: constraints.maxWidth * 0.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD7AA11),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reaction row placeholder (non-interactive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StaticIcon(
                          icon: Icons.thumb_up_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 28),
                        _StaticIcon(
                          icon: Icons.thumb_down_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 28),
                        _StaticIcon(
                          icon: Icons.chat_bubble_outline_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 28),
                        Transform.flip(
                          flipX: true,
                          child: _StaticIcon(
                            icon: Icons.reply_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description — mirrors _SectionHeader + _DescriptionCard
                    Text(
                      'Description',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.locationLabel,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.description,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),

                    // Photo proof — mirrors _ProofSection
                    if (widget.photoItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Images / Proof',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.photoItems.map((item) {
                          final size =
                              (MediaQuery.of(context).size.width - 40 - 16) / 3;
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      child: Image.memory(
                                        item.bytes,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: Image.memory(
                                  item.bytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Tips — mirrors _TipsSection
                    const SizedBox(height: 28),
                    _ReviewTipsSection(alert: alert),
                  ],
                ),
              ),
            ),

            // Send button pinned at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _dangerRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSending ? 'Sending…' : 'Send Alert',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StaticIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(6),
    child: Icon(icon, size: 26, color: color),
  );
}

class _ReviewTipsSection extends StatelessWidget {
  final AlertModel alert;
  const _ReviewTipsSection({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tips = _tipsFor(alert);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFFE12626),
            ),
            const SizedBox(width: 6),
            const Text(
              'Tips that might be helpful',
              style: TextStyle(
                color: Color(0xFFE12626),
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          tips.title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tips.intro,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...tips.steps.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.key + 1}. ',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static _TipData _tipsFor(AlertModel alert) {
    final t = alert.title.toLowerCase();
    if (t.contains('accident')) {
      return const _TipData(
        title: 'If you are in an accident',
        intro:
            'Stay Calm & Check for Injuries – Assess yourself and passengers.',
        steps: [
          'Move to Safety – If drivable, move to the side of the road.',
          'Call Emergency Services – Dial 112 immediately.',
          'Do Not Move Injured Persons – Unless there is immediate danger.',
          'Document the Scene – Take photos if it is safe to do so.',
        ],
      );
    }
    if (t.contains('flood')) {
      return const _TipData(
        title: 'If you are in a flood',
        intro: 'Move to higher ground and avoid floodwaters.',
        steps: [
          'Evacuate Early – Do not wait for water to reach your home.',
          'Avoid Floodwater – Even 15 cm can knock you down.',
          'Turn Off Utilities – Switch off electricity if safe.',
          'Call 112 and follow official instructions.',
        ],
      );
    }
    if (t.contains('fire')) {
      return const _TipData(
        title: 'If there is a fire nearby',
        intro: 'Evacuate immediately and alert others.',
        steps: [
          'Get Out Fast – Leave without collecting belongings.',
          'Stay Low – Crawl under smoke for cleaner air.',
          'Close Doors – Slows the spread of fire.',
          'Call 101 – Report the fire and your location.',
        ],
      );
    }
    return const _TipData(
      title: 'Stay safe during an emergency',
      intro: 'Keep calm and follow official guidance.',
      steps: [
        'Move away from the danger zone if safe.',
        'Call 112 to report and request assistance.',
        'Stay informed via official news and alerts.',
        'Help others if you can do so safely.',
      ],
    );
  }
}

class _TipData {
  final String title;
  final String intro;
  final List<String> steps;
  const _TipData({
    required this.title,
    required this.intro,
    required this.steps,
  });
}

// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: colorScheme.outlineVariant),
        backgroundColor: colorScheme.surface,
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

// ---------------------------------------------------------------------------
// Danger level selector – three tappable cards (Low / Medium / High)
// ---------------------------------------------------------------------------

class _DangerLevelSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _DangerLevelSelector({required this.value, required this.onChanged});

  static const _levels = [
    _DangerLevel(
      label: 'Low',
      description: 'Minor risk,\nno threat',
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFE8F5E9),
      darkBgColor: Color(0xFF1B3A1D),
      value: 0.16,
    ),
    _DangerLevel(
      label: 'Medium',
      description: 'Moderate risk,\nneeds attention',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFF57F17),
      bgColor: Color(0xFFFFF8E1),
      darkBgColor: Color(0xFF3A2E00),
      value: 0.50,
    ),
    _DangerLevel(
      label: 'High',
      description: 'Severe risk,\nimmediate danger',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFB71C1C),
      bgColor: Color(0xFFFFEBEE),
      darkBgColor: Color(0xFF3A0A0A),
      value: 0.84,
    ),
  ];

  int get _selectedIndex {
    if (value >= 0.67) return 2;
    if (value >= 0.34) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedIndex;

    return Row(
      children: List.generate(_levels.length, (i) {
        final level = _levels[i];
        final isSelected = i == selected;
        final bg = isDark ? level.darkBgColor : level.bgColor;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _levels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(level.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? bg
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? level.color
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: level.color.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        level.icon,
                        color: isSelected
                            ? level.color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? level.color
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        height: 1.4,
                        color: isSelected
                            ? level.color.withValues(alpha: 0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DangerLevel {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color darkBgColor;
  final double value;

  const _DangerLevel({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.darkBgColor,
    required this.value,
  });
}

class _EmergencyType {
  final String id;
  final String label;
  final IconData icon;

  const _EmergencyType(this.id, this.label, this.icon);
}

enum _ProofType {
  photo('Photo', Icons.photo_camera, 'photo'),
  video('Video', Icons.videocam, 'video'),
  voice('Voice', Icons.keyboard_voice, 'voice');

  final String label;
  final IconData icon;
  final String storageKey;
  const _ProofType(this.label, this.icon, this.storageKey);
}

class _ProofItem {
  final String id;
  final _ProofType type;
  final String name;
  final String sizeLabel;
  final Uint8List bytes;

  const _ProofItem({
    required this.id,
    required this.type,
    required this.name,
    required this.sizeLabel,
    required this.bytes,
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
