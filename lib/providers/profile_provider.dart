import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';

class ProfileProvider with ChangeNotifier {
  late Box<Profile> _profileBox;
  late Box _settingsBox;
  
  List<Profile> _profiles = [];
  String? _activeProfileId;

  List<Profile> get profiles => _profiles;
  
  Profile? get activeProfile {
    if (_activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      return null;
    }
  }

  String? get activeProfileId => _activeProfileId;

  Future<void> init() async {
    _profileBox = Hive.box<Profile>('profiles');
    _settingsBox = Hive.box('settings');
    
    _profiles = _profileBox.values.toList();
    _activeProfileId = _settingsBox.get('activeProfileId');

    // Ensure at least one profile exists
    if (_profiles.isEmpty) {
      final defaultProfile = Profile(
        id: 'default_main',
        name: 'Main Profile',
        createdAt: DateTime.now(),
      );
      await _profileBox.put(defaultProfile.id, defaultProfile);
      _profiles = [defaultProfile];
      _activeProfileId = defaultProfile.id;
      await _settingsBox.put('activeProfileId', _activeProfileId);
    } else if (_activeProfileId == null || !(_profiles.any((p) => p.id == _activeProfileId))) {
      _activeProfileId = _profiles.first.id;
      await _settingsBox.put('activeProfileId', _activeProfileId);
    }
    
    notifyListeners();
  }

  Future<void> addProfile(String name) async {
    final newProfile = Profile(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _profileBox.put(newProfile.id, newProfile);
    _profiles = _profileBox.values.toList();
    notifyListeners();
  }

  Future<void> updateProfile(String id, String newName) async {
    final profile = _profileBox.get(id);
    if (profile != null) {
      profile.name = newName;
      await profile.save();
      _profiles = _profileBox.values.toList();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return; // Prevent deleting the last profile
    
    await _profileBox.delete(id);
    _profiles = _profileBox.values.toList();
    
    if (_activeProfileId == id) {
      _activeProfileId = _profiles.first.id;
      await _settingsBox.put('activeProfileId', _activeProfileId);
    }
    
    notifyListeners();
  }

  Future<void> setActiveProfile(String id) async {
    if (_activeProfileId == id) return;
    _activeProfileId = id;
    await _settingsBox.put('activeProfileId', id);
    notifyListeners();
  }
}
