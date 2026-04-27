import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Admin-only Firestore operations.
/// All methods should only be called when the current user has [UserRole.admin].
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection(AppConstants.alertsCollection);

  // ── Stats ────────────────────────────────────────────────────────────────

  /// Stream of total user count.
  Stream<int> streamUserCount() => _users.snapshots().map((s) => s.size);

  /// Stream of total alert count.
  Stream<int> streamAlertCount() => _alerts.snapshots().map((s) => s.size);

  /// Stream of unverified alert count.
  Stream<int> streamUnverifiedAlertCount() => _alerts
      .where('verifiedByGovernment', isEqualTo: false)
      .snapshots()
      .map((s) => s.size);

  /// Stream of critical (red) alert count.
  Stream<int> streamCriticalAlertCount() => _alerts
      .where('alertLevel', isEqualTo: 'red')
      .snapshots()
      .map((s) => s.size);

  // ── Users ────────────────────────────────────────────────────────────────

  /// Real-time stream of all users, newest first.
  Stream<List<UserModel>> streamAllUsers() => _users
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());

  /// Update a user's role.
  Future<void> setUserRole(String uid, UserRole role) => _users.doc(uid).update(
    {'role': role.value, 'updatedAt': FieldValue.serverTimestamp()},
  );

  /// Delete a user document from Firestore (does NOT delete Firebase Auth account).
  Future<void> deleteUser(String uid) => _users.doc(uid).delete();

  // ── Alerts ───────────────────────────────────────────────────────────────

  /// Real-time stream of all alerts, newest first.
  Stream<List<AlertModel>> streamAllAlerts() => _alerts
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(AlertModel.fromFirestore).toList());

  /// Verify an alert.
  Future<void> verifyAlert(String alertId) => _alerts.doc(alertId).update({
    'verifiedByGovernment': true,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Unverify an alert.
  Future<void> unverifyAlert(String alertId) => _alerts.doc(alertId).update({
    'verifiedByGovernment': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Delete an alert.
  Future<void> deleteAlert(String alertId) => _alerts.doc(alertId).delete();
}
