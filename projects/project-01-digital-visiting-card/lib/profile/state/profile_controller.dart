import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
import '../models/profile.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;
  Profile _profile = Profile.sample;
  bool _isLoading = true;
  bool _hasStartedLoading = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _loadError;

  Profile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadError => _loadError;

  Future<void> load() async {
    if (_isLoading && _hasStartedLoading) return;

    final isRetry = _hasStartedLoading;
    _hasStartedLoading = true;
    _isLoading = true;
    _loadError = null;
    if (isRetry) _notifyListeners();
    try {
      final savedProfile = await _repository.load();
      if (savedProfile != null) _profile = savedProfile;
    } on Exception catch (error, stackTrace) {
      developer.log(
        'Could not load the saved profile.',
        name: 'digital_visiting_card.profile',
        error: error,
        stackTrace: stackTrace,
      );
      _loadError =
          'Your saved profile could not be loaded. Check your device storage and try again.';
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> save(Profile profile) async {
    if (_isDisposed) {
      throw StateError(
        'Cannot save a profile after the controller is disposed.',
      );
    }
    if (_isLoading) {
      throw StateError('Cannot save a profile before loading has completed.');
    }

    _isSaving = true;
    _notifyListeners();
    try {
      await _repository.save(profile);
      _profile = profile;
      _loadError = null;
    } finally {
      _isSaving = false;
      _notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }
}
