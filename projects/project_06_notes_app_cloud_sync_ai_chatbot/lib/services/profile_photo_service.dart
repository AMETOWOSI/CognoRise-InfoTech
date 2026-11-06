import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class ProfilePhotoService {
  Future<String?> pickAndUpload(String userId);

  Future<void> delete(String userId);
}

class FirebaseProfilePhotoService implements ProfilePhotoService {
  FirebaseProfilePhotoService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _imagePicker = imagePicker ?? ImagePicker();

  static const _maxPhotoBytes = 5 * 1024 * 1024;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  @override
  Future<String?> pickAndUpload(String userId) async {
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (selected == null) return null;

    final user = _requireOwner(userId);
    final file = File(selected.path);
    final size = await file.length();
    if (size == 0 || size > _maxPhotoBytes) {
      throw const ProfilePhotoException('Choose an image smaller than 5 MB.');
    }

    final contentType = selected.mimeType ?? 'image/jpeg';
    if (!contentType.startsWith('image/')) {
      throw const ProfilePhotoException('Choose a supported image file.');
    }

    final reference = _photoReference(userId);
    await reference.putFile(file, SettableMetadata(contentType: contentType));
    final downloadUrl = await reference.getDownloadURL();
    await user.updatePhotoURL(downloadUrl);
    await user.reload();
    return downloadUrl;
  }

  @override
  Future<void> delete(String userId) async {
    final user = _requireOwner(userId);
    await _photoReference(userId).delete();
    await user.updatePhotoURL(null);
    await user.reload();
  }

  User _requireOwner(String userId) {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('A signed-in owner is required to manage this photo.');
    }
    return user;
  }

  Reference _photoReference(String userId) =>
      _storage.ref('users/$userId/profile/avatar');
}

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}
