import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class ProfilePhotoService {
  Future<String?> loadLocalPhoto(String userId);

  Future<String?> pickAndSave(String userId);

  Future<void> delete(String userId);
}

class LocalProfilePhotoService implements ProfilePhotoService {
  LocalProfilePhotoService({
    ImagePicker? imagePicker,
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const _maxPhotoBytes = 5 * 1024 * 1024;

  final ImagePicker _imagePicker;
  final Future<Directory> Function() _supportDirectoryProvider;

  @override
  Future<String?> loadLocalPhoto(String userId) async {
    final file = File(await _photoPath(userId));
    return await file.exists() ? file.path : null;
  }

  @override
  Future<String?> pickAndSave(String userId) async {
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (selected == null) return null;

    final file = File(selected.path);
    final size = await file.length();
    if (size == 0 || size > _maxPhotoBytes) {
      throw const ProfilePhotoException(
        'Choose a non-empty image smaller than 5 MB.',
      );
    }

    final contentType = selected.mimeType ?? 'image/jpeg';
    if (!contentType.startsWith('image/')) {
      throw const ProfilePhotoException('Choose a supported image file.');
    }

    final path = await _photoPath(userId);
    await File(path).parent.create(recursive: true);
    await selected.saveTo(path);
    return path;
  }

  @override
  Future<void> delete(String userId) async {
    final file = File(await _photoPath(userId));
    if (await file.exists()) await file.delete();
  }

  Future<String> _photoPath(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Invalid account ID.');
    }
    final directory = await _supportDirectoryProvider();
    final accountKey = base64Url
        .encode(utf8.encode(userId))
        .replaceAll('=', '');
    return '${directory.path}${Platform.pathSeparator}profile_photos'
        '${Platform.pathSeparator}$accountKey'
        '${Platform.pathSeparator}avatar';
  }
}

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}
