import 'dart:async';
import 'dart:math' as math;

import 'package:digital_visiting_card/app/app_colors.dart';
import 'package:digital_visiting_card/profile/data/profile_repository.dart';
import 'package:digital_visiting_card/profile/models/profile.dart';
import 'package:digital_visiting_card/profile/state/profile_controller.dart';
import 'package:digital_visiting_card/profile/utils/profile_link_utils.dart';
import 'package:digital_visiting_card/profile/utils/vcard_builder.dart';
import 'package:flutter/material.dart' show Color, Colors;
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = _relativeLuminance(first);
  final secondLuminance = _relativeLuminance(second);
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double linearize(int channel) {
    final value = channel / 255;
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize((color.r * 255).round()) +
      0.7152 * linearize((color.g * 255).round()) +
      0.0722 * linearize((color.b * 255).round());
}

class _DeferredProfileRepository implements ProfileRepository {
  final Completer<Profile?> loadCompleter = Completer<Profile?>();

  @override
  Future<Profile?> load() => loadCompleter.future;

  @override
  Future<void> save(Profile profile) async {}
}

class _RetryProfileRepository implements ProfileRepository {
  var shouldFail = true;

  @override
  Future<Profile?> load() async {
    if (shouldFail) {
      shouldFail = false;
      throw Exception('Storage detail that should not be shown to the user.');
    }
    return Profile.sample;
  }

  @override
  Future<void> save(Profile profile) async {}
}

void main() {
  test('provides readable contrast for the primary text and button colors', () {
    expect(
      _contrastRatio(AppColors.muted, AppColors.canvas),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(Colors.white, AppColors.purple),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(AppColors.yellow, AppColors.deepPurple),
      greaterThanOrEqualTo(4.5),
    );
  });

  group('profile link helpers', () {
    test(
      'validates common email addresses and rejects malformed addresses',
      () {
        for (final email in ['ama@example.test', 'first.last+tag@example.co']) {
          expect(isValidEmailAddress(email), isTrue, reason: email);
        }

        for (final email in [
          'person..name@example.test',
          'person@example..test',
          'person@-example.test',
          'person@example-.test',
          'person@example',
          'person@@example.test',
        ]) {
          expect(isValidEmailAddress(email), isFalse, reason: email);
        }
      },
    );

    test('accepts HTTPS URLs and rejects unsafe or malformed URLs', () {
      expect(
        profileWebUri('https://example.com'),
        Uri.https('example.com', ''),
      );
      expect(profileWebUri('http://example.com'), isNull);
      expect(profileWebUri('https://user:password@example.com'), isNull);
      expect(profileWebUri('javascript:alert(1)'), isNull);
    });

    test('normalizes valid international WhatsApp numbers', () {
      expect(
        whatsappUri('+1 (555) 010-2040'),
        Uri.https('wa.me', '/15550102040'),
      );
      expect(whatsappUri('555-010'), isNull);
      expect(whatsappUri('+1 (555) 010-ABC0'), isNull);
    });
  });

  group('Profile', () {
    test('uses Ama KWATCHA as the Togo-based starter profile', () {
      expect(Profile.sample.fullName, 'Ama KWATCHA');
      expect(Profile.sample.location, 'Togo');
      expect(Profile.sample.email, isEmpty);
      expect(Profile.sample.phone, isEmpty);
      expect(Profile.sample.portfolioUrl, isEmpty);
      expect(Profile.sample.whatsappNumber, isEmpty);
      expect(Profile.sample.facebookUrl, isEmpty);
      expect(Profile.sample.linkedinUrl, isEmpty);
      expect(Profile.sample.instagramUrl, isEmpty);
    });

    test('round-trips its fields through JSON', () {
      final profile = Profile.sample.copyWith(
        fullName: 'Jordan Lee',
        skills: ['Flutter', 'Dart'],
      );

      expect(Profile.fromJson(profile.toJson()).toJson(), profile.toJson());
    });

    test('keeps skills immutable', () {
      expect(
        () => Profile.sample.skills.add('Unexpected'),
        throwsUnsupportedError,
      );
    });

    test('rejects malformed profile JSON', () {
      expect(() => Profile.fromJson({'fullName': 42}), throwsFormatException);
      expect(() => Profile.fromJson({'fullName': '  '}), throwsFormatException);
    });
  });

  group('ProfileController', () {
    test('can retry loading after a repository failure', () async {
      final controller = ProfileController(
        repository: _RetryProfileRepository(),
      );

      await controller.load();
      expect(controller.isLoading, isFalse);
      expect(controller.loadError, isNotNull);
      expect(controller.loadError, isNot(contains('Storage detail')));

      await controller.load();
      expect(controller.isLoading, isFalse);
      expect(controller.loadError, isNull);
      expect(controller.profile.fullName, 'Ama KWATCHA');

      controller.dispose();
    });

    test('prevents saving before the stored profile has loaded', () async {
      final repository = _DeferredProfileRepository();
      final controller = ProfileController(repository: repository);
      final load = controller.load();

      await expectLater(controller.save(Profile.sample), throwsStateError);

      repository.loadCompleter.complete(Profile.sample);
      await load;
      controller.dispose();
    });

    test('does not notify listeners after disposal during loading', () async {
      final repository = _DeferredProfileRepository();
      final controller = ProfileController(repository: repository);
      var notified = false;
      controller.addListener(() => notified = true);
      final load = controller.load();

      controller.dispose();
      repository.loadCompleter.complete(Profile.sample);
      await expectLater(load, completes);

      expect(notified, isFalse);
    });
  });

  group('buildVCard', () {
    test('includes contact details and configured web URLs', () {
      final profile = Profile.sample.copyWith(
        email: 'ama@example.test',
        phone: '+228 90 00 00 00',
        portfolioUrl: 'https://portfolio.example.test',
        linkedinUrl: 'https://linkedin.example.test/ama',
      );
      final card = buildVCard(profile);

      expect(card, contains('BEGIN:VCARD\r\n'));
      expect(card, contains('VERSION:3.0\r\n'));
      expect(card, contains('FN:Ama KWATCHA\r\n'));
      expect(card, contains('TEL;TYPE=CELL:+228 90 00 00 00'));
      expect(card, contains('EMAIL;TYPE=INTERNET:ama@example.test'));
      expect(card, contains('URL:https://portfolio.example.test'));
      expect(card, contains('URL:https://linkedin.example.test/ama'));
      expect(card, endsWith('END:VCARD'));
    });

    test('does not publish contact details that were not provided', () {
      final card = buildVCard(Profile.sample);

      expect(card, contains('FN:Ama KWATCHA\r\n'));
      expect(card, isNot(contains('TEL;')));
      expect(card, isNot(contains('EMAIL;')));
      expect(card, isNot(contains('URL:')));
    });

    test('omits blank optional URLs and escapes vCard text', () {
      final profile = Profile.sample.copyWith(
        fullName: 'Ama, KWATCHA',
        portfolioUrl: '',
        linkedinUrl: '',
        facebookUrl: '',
        instagramUrl: '',
        bio: 'Design; build, repeat',
      );

      final card = buildVCard(profile);

      expect(card, contains(r'FN:Ama\, KWATCHA'));
      expect(card, contains(r'NOTE:Design\; build\, repeat'));
      expect(card, isNot(contains('URL:')));
    });

    test('does not encode invalid URLs as vCard properties', () {
      final profile = Profile.sample.copyWith(
        portfolioUrl: 'BEGIN:VCARD\r\nTEL:attacker',
        linkedinUrl: 'javascript:alert(1)',
      );

      final card = buildVCard(profile);

      expect(card, isNot(contains('BEGIN:VCARD\r\nTEL:attacker')));
      expect(card, isNot(contains('javascript:')));
    });
  });
}
