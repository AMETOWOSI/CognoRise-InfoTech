import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> load();

  Future<void> save(Profile profile);
}

class SharedPreferencesProfileRepository implements ProfileRepository {
  static const _storageKey = 'digital_visiting_card.profile.v1';

  @override
  Future<Profile?> load() async {
    final preferences = SharedPreferencesAsync();
    final storedValue = await preferences.getString(_storageKey);
    if (storedValue == null) return null;

    final Object? decoded = jsonDecode(storedValue);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The saved profile is not a valid object.');
    }
    return Profile.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> save(Profile profile) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(_storageKey, jsonEncode(profile.toJson()));
  }
}
