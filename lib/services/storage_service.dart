import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// ── Size limits (raw bytes before compression) ────────────────────────────────
const int kMaxPhotoBytes = 5 * 1024 * 1024; // 5 MB input
const int kMaxVideoBytes = 50 * 1024 * 1024; // 50 MB (not stored as Base64)
const int kMaxAudioBytes = 10 * 1024 * 1024; // 10 MB (not stored as Base64)

// After compression we target ≤ 700 KB so the Base64 string (~933 KB) fits
// comfortably inside Firestore's 1 MB document limit.
const int _targetCompressedBytes = 700 * 1024;

class FileTooLargeException implements Exception {
  final String message;
  const FileTooLargeException(this.message);
  @override
  String toString() => message;
}

class ProofStorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _proofsCol(String alertId) =>
      _db.collection('alerts').doc(alertId).collection('proofs');

  /// Compress [bytes] to JPEG, encode as Base64, and save to
  /// `alerts/{alertId}/proofs/{autoId}`.
  ///
  /// Returns the Firestore document ID of the saved proof.
  /// Throws [FileTooLargeException] if the raw input exceeds [kMaxPhotoBytes].
  Future<String> saveImageProof({
    required String alertId,
    required Uint8List bytes,
    required String fileName,
    void Function(String status)? onStatus,
  }) async {
    // ── Input size guard ──────────────────────────────────────────────────
    if (bytes.length > kMaxPhotoBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw FileTooLargeException(
        'Image is $mb MB — photos must be under 5 MB.',
      );
    }

    // ── Compress ──────────────────────────────────────────────────────────
    onStatus?.call('Compressing image…');

    Uint8List compressed = await _compressToTarget(bytes);

    // ── Base64 encode ─────────────────────────────────────────────────────
    onStatus?.call('Encoding image…');
    final base64String = base64Encode(compressed);

    // Double-check it fits in a Firestore document (< 1 MB string)
    if (base64String.length > 900 * 1024) {
      // Re-compress harder if still too large
      compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 600,
        minHeight: 600,
        quality: 40,
        format: CompressFormat.jpeg,
      );
      final retry = base64Encode(compressed);
      if (retry.length > 900 * 1024) {
        throw FileTooLargeException(
          'Image could not be compressed small enough to store. '
          'Please choose a smaller image.',
        );
      }
      return _saveToFirestore(
        alertId: alertId,
        base64String: retry,
        fileName: fileName,
        compressedBytes: compressed,
        onStatus: onStatus,
      );
    }

    return _saveToFirestore(
      alertId: alertId,
      base64String: base64String,
      fileName: fileName,
      compressedBytes: compressed,
      onStatus: onStatus,
    );
  }

  Future<String> _saveToFirestore({
    required String alertId,
    required String base64String,
    required String fileName,
    required Uint8List compressedBytes,
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Saving proof…');
    final doc = await _proofsCol(alertId).add({
      'type': 'photo',
      'fileName': fileName,
      'base64': base64String,
      'sizeBytes': compressedBytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Compress [bytes] iteratively until the result is ≤ [_targetCompressedBytes].
  static Future<Uint8List> _compressToTarget(Uint8List bytes) async {
    // Start at quality 80, step down by 15 each iteration
    int quality = 80;
    Uint8List result = bytes;

    while (quality >= 25) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      result = compressed;
      if (compressed.length <= _targetCompressedBytes) break;
      quality -= 15;
    }

    return result;
  }

  /// Stream all proof documents for an alert, ordered by creation time.
  Stream<List<ProofDocument>> streamProofs(String alertId) {
    return _proofsCol(alertId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ProofDocument.fromFirestore(doc)).toList(),
        );
  }

  /// Delete a single proof document.
  Future<void> deleteProof(String alertId, String proofId) =>
      _proofsCol(alertId).doc(proofId).delete();
}

// ── Data class ────────────────────────────────────────────────────────────────

class ProofDocument {
  final String id;
  final String type;
  final String fileName;
  final String base64;
  final int sizeBytes;
  final DateTime? createdAt;

  const ProofDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.base64,
    required this.sizeBytes,
    this.createdAt,
  });

  factory ProofDocument.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ProofDocument(
      id: doc.id,
      type: d['type'] as String? ?? 'photo',
      fileName: d['fileName'] as String? ?? '',
      base64: d['base64'] as String? ?? '',
      sizeBytes: (d['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Decode Base64 back to raw bytes for display.
  Uint8List get bytes => base64Decode(base64);
}
