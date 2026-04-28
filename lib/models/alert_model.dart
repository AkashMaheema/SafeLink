import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

// ── Alert level ──────────────────────────────────────────────────────────────

/// Severity colour-coding for an alert.
/// - [green]  → Informational / low risk
/// - [yellow] → Moderate risk — take precautions
/// - [red]    → High risk — immediate action required
enum AlertLevel { green, yellow, red }

extension AlertLevelX on AlertLevel {
  String get value => name; // 'green' | 'yellow' | 'red'

  static AlertLevel fromString(String? raw) => AlertLevel.values.firstWhere(
    (l) => l.name == raw,
    orElse: () => AlertLevel.green,
  );

  /// Numeric weight — useful for sorting highest-risk first.
  int get weight => switch (this) {
    AlertLevel.green => 0,
    AlertLevel.yellow => 1,
    AlertLevel.red => 2,
  };
}

// ── GeoPoint wrapper ─────────────────────────────────────────────────────────

/// Thin wrapper so the rest of the app never imports Firestore just for coords.
class AlertLocation {
  final double latitude;
  final double longitude;

  const AlertLocation({required this.latitude, required this.longitude});

  factory AlertLocation.fromGeoPoint(GeoPoint gp) =>
      AlertLocation(latitude: gp.latitude, longitude: gp.longitude);

  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory AlertLocation.fromMap(Map<String, dynamic> m) => AlertLocation(
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
  );

  /// Haversine distance to [other] in **metres**.
  double distanceTo(AlertLocation other) {
    const r = 6371000.0; // Earth radius in metres
    final lat1 = latitude * (math.pi / 180);
    final lat2 = other.latitude * (math.pi / 180);
    final dLat = (other.latitude - latitude) * (math.pi / 180);
    final dLon = (other.longitude - longitude) * (math.pi / 180);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}

// ── AlertModel ───────────────────────────────────────────────────────────────

class AlertModel {
  final String id;
  final String title;
  final String description;
  final AlertLevel alertLevel;
  final double dangerLevel;
  final AlertLocation geoLocation;

  /// Affected radius in **metres**.
  final double radius;

  final bool verifiedByGovernment;
  final String createdByUid;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Download URLs of uploaded proof files (photos, videos, audio).
  final List<String> proofUrls;

  const AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.alertLevel,
    this.dangerLevel = 0.5,
    required this.geoLocation,
    required this.radius,
    this.verifiedByGovernment = false,
    required this.createdByUid,
    required this.createdAt,
    this.updatedAt,
    this.proofUrls = const [],
  });

  // ── Factories ────────────────────────────────────────────────────────────

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel.fromMap(data, doc.id);
  }

  factory AlertModel.fromMap(Map<String, dynamic> m, String id) {
    // geoLocation can be stored as a Firestore GeoPoint or as a sub-map
    final AlertLocation location;
    final raw = m['geoLocation'];
    if (raw is GeoPoint) {
      location = AlertLocation.fromGeoPoint(raw);
    } else if (raw is Map<String, dynamic>) {
      location = AlertLocation.fromMap(raw);
    } else {
      location = const AlertLocation(latitude: 0, longitude: 0);
    }

    final parsedLevel = AlertLevelX.fromString(m['alertLevel'] as String?);
    final rawDanger = (m['dangerLevel'] as num?)?.toDouble();
    final resolvedDanger = rawDanger ?? (parsedLevel.weight / 2);

    return AlertModel(
      id: id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      alertLevel: parsedLevel,
      dangerLevel: resolvedDanger.clamp(0.0, 1.0),
      geoLocation: location,
      radius: (m['radius'] as num?)?.toDouble() ?? 0.0,
      verifiedByGovernment: m['verifiedByGovernment'] as bool? ?? false,
      createdByUid: m['createdByUid'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      proofUrls:
          (m['proofUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'alertLevel': alertLevel.value,
    'dangerLevel': dangerLevel,
    'geoLocation': geoLocation.toGeoPoint(),
    'radius': radius,
    'verifiedByGovernment': verifiedByGovernment,
    'createdByUid': createdByUid,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    'proofUrls': proofUrls,
  };

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns true when [userLocation] falls within [radius] metres of this
  /// alert's [geoLocation].
  bool isWithinRadius(AlertLocation userLocation) =>
      geoLocation.distanceTo(userLocation) <= radius;

  AlertModel copyWith({
    String? title,
    String? description,
    AlertLevel? alertLevel,
    double? dangerLevel,
    AlertLocation? geoLocation,
    double? radius,
    bool? verifiedByGovernment,
    List<String>? proofUrls,
  }) => AlertModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    alertLevel: alertLevel ?? this.alertLevel,
    dangerLevel: dangerLevel ?? this.dangerLevel,
    geoLocation: geoLocation ?? this.geoLocation,
    radius: radius ?? this.radius,
    verifiedByGovernment: verifiedByGovernment ?? this.verifiedByGovernment,
    createdByUid: createdByUid,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    proofUrls: proofUrls ?? this.proofUrls,
  );

  @override
  String toString() =>
      'AlertModel(id: $id, title: $title, level: ${alertLevel.value})';
}
