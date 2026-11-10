import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_06_notes_app_cloud_sync_ai_chatbot/services/profile_photo_service.dart';

void main() {
  test(
    'loads and removes a profile photo from its account-local directory',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'noteflow_profile_photo_test_',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));

      final accountKey = base64Url
          .encode(utf8.encode('test-user'))
          .replaceAll('=', '');
      final photo = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}profile_photos'
        '${Platform.pathSeparator}$accountKey'
        '${Platform.pathSeparator}avatar',
      );
      await photo.parent.create(recursive: true);
      await photo.writeAsBytes([1, 2, 3]);

      final service = LocalProfilePhotoService(
        supportDirectoryProvider: () async => temporaryDirectory,
      );

      expect(await service.loadLocalPhoto('test-user'), photo.path);
      expect(await service.loadLocalPhoto('another-user'), isNull);

      await service.delete('test-user');

      expect(await service.loadLocalPhoto('test-user'), isNull);
    },
  );

  test('rejects an empty account ID', () {
    final service = LocalProfilePhotoService(
      supportDirectoryProvider: () async => Directory.systemTemp,
    );

    expect(service.loadLocalPhoto(''), throwsArgumentError);
  });
}
