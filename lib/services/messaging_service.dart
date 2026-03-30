import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/alert_model.dart';

typedef AlertCallback = void Function(AlertModel alert);

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final List<AlertCallback> _alertCallbacks = [];

  /// Request notification permissions and initialise listeners
  Future<void> init() async {
    // Request permission (iOS / web)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

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

  /// Parse and handle incoming alert messages
  void _handleAlertMessage(RemoteMessage message) {
    try {
      final data = message.data;

      // Check if this is an emergency alert message
      if (data['type'] == 'emergency_alert') {
        final alertJson = data['alert'];
        if (alertJson != null) {
          final Map<String, dynamic> alertMap = jsonDecode(alertJson);
          final alert = AlertModel.fromMap(alertMap, alertMap['id'] ?? '');

          // Notify all registered callbacks
          for (final callback in _alertCallbacks) {
            callback(alert);
          }

          debugPrint('Alert notification received: ${alert.title}');
        }
      }
    } catch (e) {
      debugPrint('Error handling alert message: $e');
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Subscribe all users to emergency_alerts topic
  Future<void> subscribeToEmergencyAlerts() =>
      subscribeToTopic('emergency_alerts');

  /// Unsubscribe from emergency alerts
  Future<void> unsubscribeFromEmergencyAlerts() =>
      unsubscribeFromTopic('emergency_alerts');
}
