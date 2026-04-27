class AppConstants {
  AppConstants._();

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String alertsCollection = 'alerts';
  static const String incidentsCollection = 'incidents';

  // FCM topics
  static const String emergencyTopic = 'emergency_alerts';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String incidentMediaPath = 'incident_media';

  // Shared prefs keys
  static const String onboardingDone = 'onboarding_done';
  static const String darkModeEnabled = 'dark_mode_enabled';
  static const String highContrastEnabled = 'high_contrast_enabled';
  static const String largerTextEnabled = 'larger_text_enabled';
  static const String vibrationOnlyEnabled = 'vibration_only_enabled';
  static const String liveCaptionsEnabled = 'live_captions_enabled';
  static const String defaultSosAction = 'default_sos_action';
  static const String shakeToSosEnabled = 'shake_to_sos_enabled';
  static const String silentSosEnabled = 'silent_sos_enabled';
}
