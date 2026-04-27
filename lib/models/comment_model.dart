import 'package:cloud_firestore/cloud_firestore.dart';

/// A single comment left on an alert.
///
/// Stored as a subcollection:
///   alerts/{alertId}/comments/{commentId}
class CommentModel {
  final String id;
  final String alertId;
  final String uid;
  final String displayName;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.alertId,
    required this.uid,
    required this.displayName,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      alertId: data['alertId'] as String? ?? '',
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Anonymous',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'alertId': alertId,
    'uid': uid,
    'displayName': displayName,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
