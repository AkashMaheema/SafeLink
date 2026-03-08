import 'package:cloud_firestore/cloud_firestore.dart';

// ── Role enum ────────────────────────────────────────────────────────────────

/// Roles available in SafeLink.
/// - [user]       → Default role on sign-up (alias: regular citizen)
/// - [regular]    → Explicitly assigned regular citizen
/// - [admin]      → Platform administrator
/// - [government] → Government / emergency-services authority
enum UserRole { user, regular, admin, government }

extension UserRoleX on UserRole {
  String get value => name; // 'user' | 'regular' | 'admin' | 'government'

  static UserRole fromString(String? raw) {
    return UserRole.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => UserRole.user,
    );
  }

  bool get isPrivileged =>
      this == UserRole.admin || this == UserRole.government;
}

// ── UserModel ────────────────────────────────────────────────────────────────

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.phone,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Factory constructors ─────────────────────────────────────────────────

  /// Build a brand-new profile (e.g. right after sign-up).
  factory UserModel.create({
    required String uid,
    required String email,
    String displayName = '',
    UserRole role = UserRole.user,
    String? phone,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName.isEmpty ? email.split('@').first : displayName,
      role: role,
      phone: phone,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Deserialise from a Firestore [DocumentSnapshot].
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Deserialise from a plain [Map].
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: UserRoleX.fromString(map['role'] as String?),
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.value,
    'photoUrl': photoUrl,
    'phone': phone,
    'isVerified': isVerified,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  // ── copyWith ─────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? displayName,
    UserRole? role,
    String? photoUrl,
    String? phone,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, role: ${role.value})';
}
