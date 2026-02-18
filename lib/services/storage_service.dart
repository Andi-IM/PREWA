import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _boxName = 'app_data';
  static const String _secureKey = 'hive_encryption_key';

  // Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyPassword = 'password';
  static const String keyToken = 'token';
  static const String keyNamaUser = 'nama_user';
  static const String keySampleId = 'sample_id';

  late Box _box;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Singleton pattern
  static final StorageService instance = StorageService._init();
  StorageService._init();

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Create encryption key if not exists
    String? encryptionKeyString = await _secureStorage.read(key: _secureKey);
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(key: _secureKey, value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }

    final encryptionKey = base64Url.decode(encryptionKeyString);

    // Open encrypted box
    _box = await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  // Generic helpers
  Future<void> _write(String key, String? value) async {
    if (value == null) {
      await _box.delete(key);
    } else {
      await _box.put(key, value);
    }
  }

  String? _read(String key) {
    if (!_box.isOpen) return null;
    return _box.get(key) as String?;
  }

  // --- Type-safe Accessors ---

  // User ID
  Future<void> saveUserId(String value) => _write(keyUserId, value);
  String? get userId => _read(keyUserId);

  // Password
  Future<void> savePassword(String value) => _write(keyPassword, value);
  String? get password => _read(keyPassword);

  // Token
  Future<void> saveToken(String value) => _write(keyToken, value);
  String? get token => _read(keyToken);

  // Nama User
  Future<void> saveNamaUser(String value) => _write(keyNamaUser, value);
  String? get namaUser => _read(keyNamaUser);

  // Sample ID
  Future<void> saveSampleId(String value) => _write(keySampleId, value);
  String? get sampleId => _read(keySampleId);

  // Clear all data
  Future<void> clearAll() async {
    await _box.clear();
  }
}
