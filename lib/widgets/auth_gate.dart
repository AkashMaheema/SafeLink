import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_shell.dart';

/// Listens to [AuthProvider] and redirects to the appropriate screen.
/// Authenticated users go to [MainShell] (bottom nav host).
/// Unauthenticated users see [LoginScreen].
///
/// Also starts the [AlertProvider] stream once the user is known.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _streamStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isAuth = context.watch<AuthProvider>().isAuthenticated;
    if (isAuth && !_streamStarted) {
      _streamStarted = true;
      // TODO: replace with the real device location once geolocator is added.
      // For now, stream all alerts globally so HomeScreen is not blank.
      context.read<AlertProvider>().startListeningAll();
    } else if (!isAuth) {
      _streamStarted = false;
      context.read<AlertProvider>().stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );
    return isAuthenticated ? const MainShell() : const LoginScreen();
  }
}
