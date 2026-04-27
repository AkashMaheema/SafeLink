import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart';

import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isVibrationOnly = false;
  bool _isLiveCaptions = false;
  String _defaultSosAction = 'Notify Contacts';
  bool _isShakeToSos = false;
  bool _isSilentSos = false;
  bool _isLoaded = false;

  bool get isVibrationOnly => _isVibrationOnly;
  bool get isLiveCaptions => _isLiveCaptions;
  String get defaultSosAction => _defaultSosAction;
  bool get isShakeToSos => _isShakeToSos;
  bool get isSilentSos => _isSilentSos;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _loadSettingsPreference();
  }

  Future<void> _loadSettingsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isVibrationOnly = prefs.getBool(AppConstants.vibrationOnlyEnabled) ?? false;
    _isLiveCaptions = prefs.getBool(AppConstants.liveCaptionsEnabled) ?? false;
    _defaultSosAction = prefs.getString(AppConstants.defaultSosAction) ?? 'Notify Contacts';
    _isShakeToSos = prefs.getBool(AppConstants.shakeToSosEnabled) ?? false;
    _isSilentSos = prefs.getBool(AppConstants.silentSosEnabled) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setVibrationOnly(bool enabled) async {
    if (_isVibrationOnly == enabled && _isLoaded) return;
    _isVibrationOnly = enabled;
    notifyListeners();

    // Mute the phone's system volume by setting it to VIBRATE mode
    try {
      bool? isGranted = await PermissionHandler.permissionsGranted;
      if (isGranted != true) {
        // Prompt user to grant permission
        await PermissionHandler.openDoNotDisturbSetting();
      }
      
      if (enabled) {
        await SoundMode.setSoundMode(RingerModeStatus.vibrate);
      } else {
        await SoundMode.setSoundMode(RingerModeStatus.normal);
      }
    } catch (e) {
      debugPrint('Failed to set mute for Vibration Only: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.vibrationOnlyEnabled, enabled);
  }

  Future<void> setLiveCaptions(bool enabled) async {
    if (_isLiveCaptions == enabled && _isLoaded) return;
    _isLiveCaptions = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.liveCaptionsEnabled, enabled);
  }

  Future<void> setDefaultSosAction(String action) async {
    if (_defaultSosAction == action && _isLoaded) return;
    _defaultSosAction = action;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.defaultSosAction, action);
  }

  Future<void> setShakeToSos(bool enabled) async {
    if (_isShakeToSos == enabled && _isLoaded) return;
    _isShakeToSos = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.shakeToSosEnabled, enabled);
  }

  Future<void> setSilentSos(bool enabled) async {
    if (_isSilentSos == enabled && _isLoaded) return;
    _isSilentSos = enabled;
    notifyListeners();
    
    // Mute the phone's system volume when Silent SOS is ON
    try {
      bool? isGranted = await PermissionHandler.permissionsGranted;
      if (isGranted != true) {
        await PermissionHandler.openDoNotDisturbSetting();
      }
      
      if (enabled) {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
      } else {
        await SoundMode.setSoundMode(RingerModeStatus.normal);
      }
    } catch (e) {
      debugPrint('Failed to set mute for Silent SOS: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.silentSosEnabled, enabled);
  }
}
