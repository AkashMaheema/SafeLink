import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'providers/auth_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/auth_service.dart';
import 'services/alert_service.dart';
import 'services/firestore_service.dart';
import 'services/messaging_service.dart';

Future<void> _initializeFirebaseSafely() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      Firebase.app();
      return;
    }
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase initialisation ──────────────────────────────────────────────
  await _initializeFirebaseSafely();

  // ── Firestore offline persistence (unlimited cache) ──────────────────────
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ── FCM setup ────────────────────────────────────────────────────────────
  final messagingService = MessagingService();
  await messagingService.init();

  // ── Run app ──────────────────────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        // Services (plain Providers — not ChangeNotifiers)
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AlertService>(create: (_) => AlertService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<MessagingService>(create: (_) => messagingService),

        // Auth state — depends on AuthService
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
          update: (_, authService, prev) => prev ?? AuthProvider(authService),
        ),

        // Alerts — depends on AlertService
        ChangeNotifierProxyProvider<AlertService, AlertProvider>(
          create: (ctx) => AlertProvider(ctx.read<AlertService>()),
          update: (_, alertService, prev) =>
              prev ?? AlertProvider(alertService),
        ),

        // Network connectivity
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
      ],
      child: const SafeLinkApp(),
    ),
  );
}
