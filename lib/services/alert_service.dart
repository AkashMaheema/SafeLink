import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../utils/constants.dart';

/// Handles all Firestore operations for [AlertModel].
///
/// Key capabilities:
///  - Real-time stream of ALL active alerts (for admin / government users)
///  - Real-time stream filtered by proximity to a [AlertLocation]
///  - CRUD operations for creating / updating / deleting alerts
class AlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.alertsCollection);

  // ── Real-time streams ────────────────────────────────────────────────────

  /// Stream of **all** alerts, sorted by severity (red first) then newest.
  Stream<List<AlertModel>> streamAllAlerts() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final alerts = _docsToAlerts(snapshot);
          alerts.sort((a, b) {
            final bySeverity = b.alertLevel.weight.compareTo(
              a.alertLevel.weight,
            );
            if (bySeverity != 0) {
              return bySeverity;
            }
            return b.createdAt.compareTo(a.createdAt);
          });
          return alerts;
        });
  }

  /// Stream of alerts whose radius covers [userLocation].
  ///
  /// Firestore cannot do geospatial radius queries natively, so we stream
  /// all documents and filter client-side using the Haversine formula
  /// (see [AlertModel.isWithinRadius]).
  ///
  /// Optionally pass [levelFilter] to receive only alerts of a given severity.
  Stream<List<AlertModel>> streamAlertsNearLocation(
    AlertLocation userLocation, {
    AlertLevel? levelFilter,
  }) {
    // Start with the full collection; apply optional level filter server-side
    Query<Map<String, dynamic>> query = _col.orderBy(
      'createdAt',
      descending: true,
    );

    if (levelFilter != null) {
      query = query.where('alertLevel', isEqualTo: levelFilter.value);
    }

    return query.snapshots().map((snapshot) {
      final all = _docsToAlerts(snapshot);

      // Client-side proximity filter
      final nearby =
          all.where((alert) => alert.isWithinRadius(userLocation)).toList()
            ..sort((a, b) {
              final bySeverity = b.alertLevel.weight.compareTo(
                a.alertLevel.weight,
              );
              if (bySeverity != 0) {
                return bySeverity;
              }
              return b.createdAt.compareTo(a.createdAt);
            });

      return nearby;
    });
  }

  /// Stream of government-verified alerts near [userLocation].
  Stream<List<AlertModel>> streamVerifiedAlertsNearLocation(
    AlertLocation userLocation,
  ) {
    return _col
        .where('verifiedByGovernment', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return _docsToAlerts(
            snapshot,
          ).where((a) => a.isWithinRadius(userLocation)).toList()..sort((a, b) {
            final bySeverity = b.alertLevel.weight.compareTo(a.alertLevel.weight);
            if (bySeverity != 0) {
              return bySeverity;
            }
            return b.createdAt.compareTo(a.createdAt);
          });
        });
  }

  // ── One-time fetch ───────────────────────────────────────────────────────

  /// Fetch a single [AlertModel] by its [id].
  Future<AlertModel?> getAlert(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? AlertModel.fromFirestore(doc) : null;
  }

  // ── Write operations ─────────────────────────────────────────────────────

  /// Create a new alert document and return its generated [id].
  Future<String> createAlert(AlertModel alert) async {
    final ref = await _col.add(alert.toMap());
    return ref.id;
  }

  /// Update an existing alert (merge strategy).
  Future<void> updateAlert(AlertModel alert) =>
      _col.doc(alert.id).set(alert.toMap(), SetOptions(merge: true));

  /// Mark an alert as government-verified.
  Future<void> verifyAlert(String alertId) => _col.doc(alertId).update({
    'verifiedByGovernment': true,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Permanently delete an alert.
  Future<void> deleteAlert(String alertId) => _col.doc(alertId).delete();

  // ── Private helpers ──────────────────────────────────────────────────────

  List<AlertModel> _docsToAlerts(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(AlertModel.fromFirestore).toList();
}
