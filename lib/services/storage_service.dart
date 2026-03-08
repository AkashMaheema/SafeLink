import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file and return its download URL
  Future<String> uploadFile(String remotePath, File file) async {
    final ref = _storage.ref(remotePath);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  /// Delete a file by its remote path
  Future<void> deleteFile(String remotePath) {
    return _storage.ref(remotePath).delete();
  }

  /// Get the download URL for an existing file
  Future<String> getDownloadUrl(String remotePath) {
    return _storage.ref(remotePath).getDownloadURL();
  }
}
