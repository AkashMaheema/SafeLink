import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state machine exposed to the widget tree via Provider.
///
/// Responsibilities:
///  - Listens to [AuthService.authStateChanges] and keeps [userModel] in sync.
///  - Wraps every auth operation with loading + error state.
///  - Exposes role-based helpers consumed by the UI.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _init();
  }

  // ── State ────────────────────────────────────────────────────────────────

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSub;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _userModel != null;

  // ── Role helpers ─────────────────────────────────────────────────────────

  UserRole get role => _userModel?.role ?? UserRole.user;
  bool get isAdmin => role == UserRole.admin;
  bool get isGovernment => role == UserRole.government;
  bool get isPrivileged => role.isPrivileged;

  // ── Initialisation ───────────────────────────────────────────────────────

  void _init() {
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _userModel = null;
      notifyListeners();
      return;
    }
    // Fetch full profile from Firestore when auth state restores on app start
    _userModel = await _authService.getUserProfile(firebaseUser.uid);
    notifyListeners();
  }

  // ── Sign up ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    String displayName = '',
    UserRole role = UserRole.user,
    String? phone,
  }) async {
    return _run(() async {
      _userModel = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phone: phone,
      );
    });
  }

  // ── Sign in ──────────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    return _run(() async {
      _userModel = await _authService.signIn(email: email, password: password);
    });
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    return _run(() async {
      _userModel = await _authService.signInWithGoogle();
    });
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Update profile ───────────────────────────────────────────────────────

  Future<bool> updateProfile(UserModel updated) async {
    return _run(() async {
      await _authService.updateProfile(updated);
      _userModel = updated;
    });
  }

  // ── Password reset ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    return _run(() => _authService.sendPasswordResetEmail(email));
  }

  // ── Error clearing ───────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Private helper ───────────────────────────────────────────────────────

  /// Runs [action], managing loading + error state.
  /// Returns `true` on success, `false` on failure.
  Future<bool> _run(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Maps Firebase error codes to user-friendly messages.
  static String _friendlyAuthError(String code) {
    return switch (code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'The email address is not valid.',
      'weak-password' => 'Password must be at least 6 characters.',
      'user-not-found' => 'No account found for this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
