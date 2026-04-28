import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/alert_model.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

typedef AlertCallback = void Function(AlertModel alert);

/// Background message handler — must be a top-level function.
/// Fires a full-screen intent notification so the user sees the alert
/// even when the app is killed or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');

  final data = message.data;
  if (data['type'] != 'emergency_alert') return;

  try {
    final alertJson = data['alert'];
    if (alertJson == null) return;

    final Map<String, dynamic> alertMap = jsonDecode(alertJson);
    final alert = AlertModel.fromMap(alertMap, alertMap['id'] ?? '');

    // Always show full-screen notification in background
    // (we can't reliably check GPS in a background isolate)
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.showEmergencyNotification(alert);
  } catch (e) {
    debugPrint('Error in background handler: $e');
  }
}

class MessagingService {
  FirebaseMessaging? _messaging;
  final List<AlertCallback> _alertCallbacks = [];

  MessagingService() {
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('FirebaseMessaging not available: $e');
    }
  }

  /// Request notification permissions and initialise listeners
  Future<void> init() async {
    if (_messaging == null) return;

    // Request permission (iOS / web)
    await _messaging!.requestPermission(alert: true, badge: true, sound: true);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages — handle alert notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      _handleAlertMessage(message);
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleAlertMessage(message);
    });
  }

  /// Register a callback to be invoked when an alert notification arrives
  void onAlertReceived(AlertCallback callback) {
    _alertCallbacks.add(callback);
  }

  /// Unregister alert callback
  void offAlertReceived(AlertCallback callback) {
    _alertCallbacks.remove(callback);
  }

  /// Parse and handle incoming alert messages.
  /// In the foreground, we check distance against the user's SOS radius
  /// and only show the full-screen alert if the alert is nearby.
  void _handleAlertMessage(RemoteMessage message) {
    try {
      final data = message.data;

      // Check if this is an emergency alert message
      if (data['type'] == 'emergency_alert') {
        final alertJson = data['alert'];
        if (alertJson != null) {
          final Map<String, dynamic> alertMap = jsonDecode(alertJson);
          final alert = AlertModel.fromMap(alertMap, alertMap['id'] ?? '');

          // Notify all registered callbacks (for in-app UI updates)
          for (final callback in _alertCallbacks) {
            callback(alert);
          }

          // Check distance and show full-screen notification if nearby
          _checkAndShowEmergency(alert);

          debugPrint('Alert notification received: ${alert.title}');
        }
      }
    } catch (e) {
      debugPrint('Error handling alert message: $e');
    }
  }

  /// Checks the alert distance against saved SOS radius.
  /// If nearby (or if we can't determine location), show the emergency.
  Future<void> _checkAndShowEmergency(AlertModel alert) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sosRadiusKm =
          prefs.getDouble(AppConstants.sosAlertRadiusKm) ?? 30.0;

      // Try to get the last known device location from the alert provider.
      // The home screen and SOS tab both resolve the device position,
      // so we read it from prefs if available.
      final lastLat = prefs.getDouble('_last_device_lat');
      final lastLng = prefs.getDouble('_last_device_lng');

      if (lastLat != null && lastLng != null) {
        final userLoc = AlertLocation(latitude: lastLat, longitude: lastLng);
        final distanceMeters = alert.geoLocation.distanceTo(userLoc);
        final distanceKm = distanceMeters / 1000;

        if (distanceKm > sosRadiusKm) {
          debugPrint(
            'Alert "${alert.title}" is ${distanceKm.toStringAsFixed(1)} km '
            'away (radius: ${sosRadiusKm.toStringAsFixed(0)} km) — skipping.',
          );
          return;
        }
      }

      // Nearby or unknown location → show the full-screen emergency
      final notificationService = NotificationService();
      await notificationService.showEmergencyNotification(alert);

      // Also navigate to the emergency screen if the app is in the foreground
      final nav = NotificationService.navigatorKey?.currentState;
      if (nav != null) {
        nav.pushNamed('/emergency-alert', arguments: alert);
      }
    } catch (e) {
      debugPrint('Error checking emergency proximity: $e');
    }
  }

  Future<String?> getToken() async => await _messaging?.getToken();

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging?.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging?.unsubscribeFromTopic(topic);
  }

  /// Subscribe all users to emergency_alerts topic
  Future<void> subscribeToEmergencyAlerts() =>
      subscribeToTopic('emergency_alerts');

  /// Unsubscribe from emergency alerts
  Future<void> unsubscribeFromEmergencyAlerts() =>
      unsubscribeFromTopic('emergency_alerts');
}
