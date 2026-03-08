import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Low-level Firebase Auth + Firestore wrapper.
/// Responsible purely for data operations — no UI / state concerns.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream ───────────────────────────────────────────────────────────────

  /// Emits a [User] whenever the auth state changes (sign in / sign out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase [User], or null.
  User? get firebaseUser => _auth.currentUser;

  // ── Sign up ──────────────────────────────────────────────────────────────

  /// Creates a new FirebaseAuth account, then writes the user profile to
  /// Firestore under `users/{uid}`.
  Future<UserModel> signUp({
    required String email,
    required String password,
    String displayName = '',
    UserRole role = UserRole.user,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    // Persist display name on the Auth profile too
    if (displayName.isNotEmpty) {
      await firebaseUser.updateDisplayName(displayName);
    }

    final userModel = UserModel.create(
      uid: firebaseUser.uid,
      email: email,
      displayName: displayName,
      role: role,
      phone: phone,
    );

    await _saveProfile(userModel);
    return userModel;
  }

  // ── Sign in ──────────────────────────────────────────────────────────────

  /// Signs in with email + password and returns the stored [UserModel].
  /// If no Firestore profile exists yet it creates one with the default role.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    return _fetchOrCreateProfile(uid, email);
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ── Google Sign-In ───────────────────────────────────────────────────────

  /// Signs in with Google via a native account picker, then links the
  /// credential with Firebase Auth and creates/fetches the Firestore profile.
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;
    return _fetchOrCreateProfile(
      user.uid,
      user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  // ── Current user ─────────────────────────────────────────────────────────

  /// Returns the [UserModel] for [uid] from Firestore, or null if not found.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Profile CRUD ─────────────────────────────────────────────────────────

  /// Updates mutable profile fields in Firestore.
  Future<void> updateProfile(UserModel user) => _saveProfile(user);

  /// Real-time stream of the user document.
  Stream<UserModel?> streamProfile(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ── Password reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _saveProfile(UserModel user) => _db
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .set(user.toMap(), SetOptions(merge: true));

  Future<UserModel> _fetchOrCreateProfile(
    String uid,
    String email, {
    String displayName = '',
  }) async {
    final existing = await getUserProfile(uid);
    if (existing != null) return existing;

    final created = UserModel.create(
      uid: uid,
      email: email,
      displayName: displayName,
    );
    await _saveProfile(created);
    return created;
  }
}
