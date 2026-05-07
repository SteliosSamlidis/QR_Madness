import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Opens the device camera and returns the captured file, or null if the
  /// user cancelled.
  Future<File?> pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,   // compress before upload
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Opens the gallery and returns the selected file, or null if cancelled.
  Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Uploads [file] to Storage at /entries/{userId}/{timestamp}.jpg and
  /// returns the public download URL.
  Future<String> uploadEntryImage(File file, String userId) async {
    final path = 'entries/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId},
    );

    final task = await ref.putFile(file, metadata);
    return task.ref.getDownloadURL();
  }

  /// Deletes the file at the given Storage URL. Safe to call with a null URL
  /// (no-op) so callers don't need to guard.
  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    await _storage.refFromURL(url).delete();
  }
}
