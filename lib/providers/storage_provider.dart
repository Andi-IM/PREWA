import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class StorageProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  // Getters for stored data
  String? get userId => _storage.userId;
  String? get password => _storage.password;
  String? get token => _storage.token;
  String? get namaUser => _storage.namaUser;
  String? get sampleId => _storage.sampleId;

  // Actions
  Future<void> saveCredentials({
    required String userId,
    required String password,
  }) async {
    await _storage.saveUserId(userId);
    await _storage.savePassword(password);
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    await _storage.saveToken(token);
    notifyListeners();
  }

  Future<void> saveUserData({String? namaUser, String? sampleId}) async {
    if (namaUser != null) await _storage.saveNamaUser(namaUser);
    if (sampleId != null) await _storage.saveSampleId(sampleId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _storage.clearAll();
    notifyListeners();
  }
}
