import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alert_model.dart';

/// Handles local high-priority notifications with full-screen intent
/// so emergency alerts appear even on the lock screen or in background.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Global navigator key — set from main.dart so we can push routes
  /// from notification tap callbacks without a BuildContext.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Callback when an alert notification is tapped (set by main.dart).
  static void Function(AlertModel alert)? onAlertTapped;

  bool _initialized = false;

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the high-priority emergency channel
    const channel = AndroidNotificationChannel(
      'emergency_alerts_channel',
      'Emergency Alerts',
      description: 'Full-screen emergency alert notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  // ── Show emergency notification ─────────────────────────────────────────

  /// Shows a full-screen intent notification for the given alert.
  /// On Android, this appears over the lock screen and other apps.
  Future<void> showEmergencyNotification(AlertModel alert) async {
    if (!_initialized) await init();

    // Encode the alert as JSON payload so we can reconstruct it on tap
    final payload = jsonEncode({
      'id': alert.id,
      'title': alert.title,
      'description': alert.description,
      'alertLevel': alert.alertLevel.name,
      'latitude': alert.geoLocation.latitude,
      'longitude': alert.geoLocation.longitude,
      'radius': alert.radius,
      'createdByUid': alert.createdByUid,
      'createdAt': alert.createdAt.toIso8601String(),
    });

    const androidDetails = AndroidNotificationDetails(
      'emergency_alerts_channel',
      'Emergency Alerts',
      channelDescription: 'Full-screen emergency alert notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: true,
      ticker: 'Emergency Alert Nearby!',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      alert.id.hashCode, // unique id per alert
      '⚠️ EMERGENCY: ${alert.title}',
      alert.description,
      notificationDetails,
      payload: payload,
    );

    debugPrint('[NotificationService] Showed emergency notification: ${alert.title}');
  }

  // ── Dismiss ──────────────────────────────────────────────────────────────

  Future<void> dismissNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> dismissAll() async {
    await _plugin.cancelAll();
  }

  // ── Notification tap handler ─────────────────────────────────────────────

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final alert = AlertModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        alertLevel: AlertLevel.values.firstWhere(
          (e) => e.name == map['alertLevel'],
          orElse: () => AlertLevel.red,
        ),
        geoLocation: AlertLocation(
          latitude: (map['latitude'] as num).toDouble(),
          longitude: (map['longitude'] as num).toDouble(),
        ),
        radius: (map['radius'] as num).toDouble(),
        createdByUid: map['createdByUid'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

      // If a callback is registered, use it (preferred — navigates to emergency screen)
      if (onAlertTapped != null) {
        onAlertTapped!(alert);
        return;
      }

      // Fallback: use the navigator key to push the emergency alert route
      final nav = navigatorKey?.currentState;
      if (nav != null) {
        nav.pushNamed('/emergency-alert', arguments: alert);
      }
    } catch (e) {
      debugPrint('[NotificationService] Error parsing tapped notification: $e');
    }
  }

  // ── Check pending (app was opened from terminated state via notification) ─

  Future<AlertModel?> getAlertFromLaunch() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;

    final payload = details.notificationResponse?.payload;
    if (payload == null || payload.isEmpty) return null;

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return AlertModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        alertLevel: AlertLevel.values.firstWhere(
          (e) => e.name == map['alertLevel'],
          orElse: () => AlertLevel.red,
        ),
        geoLocation: AlertLocation(
          latitude: (map['latitude'] as num).toDouble(),
          longitude: (map['longitude'] as num).toDouble(),
        ),
        radius: (map['radius'] as num).toDouble(),
        createdByUid: map['createdByUid'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    } catch (e) {
      debugPrint('[NotificationService] Error parsing launch notification: $e');
      return null;
    }
  }
}
