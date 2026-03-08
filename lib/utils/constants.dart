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
}
