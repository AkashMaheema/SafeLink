import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../utils/constants.dart';

/// Handles votes and comments for alerts.
///
/// Firestore layout:
///   alerts/{alertId}/votes/{uid}      → { vote: 'up' | 'down' }
///   alerts/{alertId}/comments/{id}    → CommentModel fields
class InteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Helpers ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _votesCol(String alertId) => _db
      .collection(AppConstants.alertsCollection)
      .doc(alertId)
      .collection('votes');

  CollectionReference<Map<String, dynamic>> _commentsCol(String alertId) => _db
      .collection(AppConstants.alertsCollection)
      .doc(alertId)
      .collection('comments');

  // ── Votes ────────────────────────────────────────────────────────────────

  /// Stream of vote counts for [alertId].
  /// Emits a [VoteSummary] whenever any vote changes.
  Stream<VoteSummary> streamVotes(String alertId) {
    return _votesCol(alertId).snapshots().map((snap) {
      int up = 0;
      int down = 0;
      for (final doc in snap.docs) {
        final v = doc.data()['vote'] as String?;
        if (v == 'up') up++;
        if (v == 'down') down++;
      }
      return VoteSummary(upvotes: up, downvotes: down);
    });
  }

  /// Stream of the current user's vote ('up', 'down', or null).
  Stream<String?> streamMyVote(String alertId, String uid) {
    return _votesCol(alertId).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data()?['vote'] as String?;
    });
  }

  /// Cast or toggle a vote.
  ///
  /// - If the user hasn't voted → sets the vote.
  /// - If the user taps the same vote again → removes it (toggle off).
  /// - If the user taps the opposite vote → switches it.
  Future<void> castVote({
    required String alertId,
    required String uid,
    required String vote, // 'up' or 'down'
  }) async {
    final ref = _votesCol(alertId).doc(uid);
    final snap = await ref.get();

    if (snap.exists && snap.data()?['vote'] == vote) {
      // Same vote tapped again → remove
      await ref.delete();
    } else {
      await ref.set({'vote': vote, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  /// Real-time stream of comments for [alertId], newest first.
  Stream<List<CommentModel>> streamComments(String alertId) {
    return _commentsCol(alertId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => CommentModel.fromFirestore(doc)).toList(),
        );
  }

  /// Add a new comment.
  Future<void> addComment({
    required String alertId,
    required String uid,
    required String displayName,
    required String text,
  }) async {
    final comment = CommentModel(
      id: '',
      alertId: alertId,
      uid: uid,
      displayName: displayName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _commentsCol(alertId).add(comment.toMap());
  }

  /// Delete a comment (only the author should be allowed to do this).
  Future<void> deleteComment({
    required String alertId,
    required String commentId,
  }) => _commentsCol(alertId).doc(commentId).delete();
}

// ── VoteSummary ───────────────────────────────────────────────────────────────

class VoteSummary {
  final int upvotes;
  final int downvotes;

  const VoteSummary({required this.upvotes, required this.downvotes});

  int get total => upvotes + downvotes;

  /// 0.0 → all downvotes (red), 1.0 → all upvotes (green).
  /// Returns 0.5 when there are no votes.
  double get positiveRatio => total == 0 ? 0.5 : upvotes / total;
}
