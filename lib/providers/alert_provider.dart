import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';

/// Exposes a live, sorted list of [AlertModel]s to the widget tree.
///
/// Lifecycle:
///  1. Call [startListening] with the user's location to activate the stream.
///  2. The provider automatically re-notifies on every Firestore update.
///  3. Call [stopListening] (or rely on [dispose]) to cancel the subscription.
///  4. Call [setLocationFilter] to change the location without rebuilding the
///     entire provider.
class AlertProvider extends ChangeNotifier {
  final AlertService _alertService;

  AlertProvider(this._alertService);

  // ── Internal state ───────────────────────────────────────────────────────

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  AlertLocation? _userLocation;
  AlertLevel? _levelFilter;
  StreamSubscription<List<AlertModel>>? _sub;

  // ── Public getters ───────────────────────────────────────────────────────

  /// All active alerts (filtered + sorted by severity).
  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  /// Subset containing only [AlertLevel.red] alerts.
  List<AlertModel> get criticalAlerts =>
      _alerts.where((a) => a.alertLevel == AlertLevel.red).toList();

  /// Subset containing only government-verified alerts.
  List<AlertModel> get verifiedAlerts =>
      _alerts.where((a) => a.verifiedByGovernment).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasAlerts => _alerts.isNotEmpty;
  int get alertCount => _alerts.length;

  /// The location currently used for proximity filtering, or null for all.
  AlertLocation? get userLocation => _userLocation;

  // ── Stream control ───────────────────────────────────────────────────────

  /// Begin (or restart) listening to alerts filtered by [location].
  ///
  /// Optionally pass [levelFilter] to restrict by severity.
  void startListening(AlertLocation location, {AlertLevel? levelFilter}) {
    _userLocation = location;
    _levelFilter = levelFilter;
    _resubscribe();
  }

  /// Listen to **all** alerts without any proximity filter
  /// (intended for admin / government users).
  void startListeningAll() {
    _userLocation = null;
    _levelFilter = null;
    _resubscribe(useGlobal: true);
  }

  /// Change the user's location on the fly — re-subscribes automatically.
  void setLocationFilter(AlertLocation newLocation) {
    if (_userLocation == null) return; // was using global stream
    _userLocation = newLocation;
    _resubscribe();
  }

  /// Change severity filter on the fly.
  void setLevelFilter(AlertLevel? level) {
    _levelFilter = level;
    _resubscribe();
  }

  /// Cancel the Firestore subscription.
  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Manual helpers ───────────────────────────────────────────────────────

  /// Clears any current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  void _resubscribe({bool useGlobal = false}) {
    _sub?.cancel();
    _setLoading(true);
    _errorMessage = null;

    final stream = useGlobal
        ? _alertService.streamAllAlerts()
        : _alertService.streamAlertsNearLocation(
            _userLocation!,
            levelFilter: _levelFilter,
          );

    _sub = stream.listen(
      (incoming) {
        _alerts = incoming;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
