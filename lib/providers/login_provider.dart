import 'package:flutter/material.dart';
import 'storage_provider.dart';
import '../services/api_service.dart';

enum LoginStatus { idle, loading, success, error }

enum LoginNavigationTarget { sampleRecord, presensi, resample }

class LoginResult {
  final LoginStatus status;
  final String? errorMessage;
  final LoginNavigationTarget? navigationTarget;
  final String? ceklok;
  final String? tglKerja;

  LoginResult({
    required this.status,
    this.errorMessage,
    this.navigationTarget,
    this.ceklok,
    this.tglKerja,
  });

  factory LoginResult.idle() => LoginResult(status: LoginStatus.idle);

  factory LoginResult.success({
    required LoginNavigationTarget target,
    String? ceklok,
    String? tglKerja,
  }) {
    return LoginResult(
      status: LoginStatus.success,
      navigationTarget: target,
      ceklok: ceklok,
      tglKerja: tglKerja,
    );
  }

  factory LoginResult.error(String message) {
    return LoginResult(status: LoginStatus.error, errorMessage: message);
  }
}

class LoginProvider extends ChangeNotifier {
  final StorageProvider _storage;
  final ApiService _api;

  LoginStatus _status = LoginStatus.idle;
  String? _userId;
  String? _password;

  LoginProvider(this._storage, this._api);

  LoginStatus get status => _status;
  String? get userId => _userId ?? _storage.userId;
  String? get password => _password ?? _storage.password;

  void setCredentials(String userId, String password) {
    _userId = userId;
    _password = password;
    notifyListeners();
  }

  void reset() {
    _status = LoginStatus.idle;
    notifyListeners();
  }

  Future<LoginResult> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return LoginResult.error('Username dan Password harus diisi');
    }

    _status = LoginStatus.loading;
    notifyListeners();

    try {
      debugPrint('=== LOGIN REQUEST ===');
      debugPrint('URL: ${_api.baseUrl}${_api.loginEndpoint}');
      debugPrint('Payload: username=$username&password=****');

      final response = await _api.login(username: username, password: password);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('====================');

      if (response.isSuccess && response.hasData) {
        final data = response.data!;
        final logData = Map<String, dynamic>.from(data);
        if (logData.containsKey('token')) {
          logData['token'] = '****';
        }
        debugPrint('Parsed Data: $logData');

        if (data['status'] == 'OK') {
          await _storage.saveCredentials(userId: username, password: password);
          await _storage.saveToken(data['token'] ?? '');
          await _storage.saveUserData(
            namaUser: data['nama_user'] ?? '',
            sampleId: data['sample_id']?.toString() ?? '',
          );

          final statusTraining = data['status_training'];
          final ceklok = data['ceklok']?.toString();
          final tglKerja = data['tgl_kerja']?.toString();

          int? statusTrainingInt;
          if (statusTraining is int) {
            statusTrainingInt = statusTraining;
          } else if (statusTraining is String) {
            statusTrainingInt = int.tryParse(statusTraining);
          }

          LoginNavigationTarget target;
          if (statusTrainingInt == 0) {
            target = LoginNavigationTarget.sampleRecord;
          } else if (statusTrainingInt == 1) {
            target = LoginNavigationTarget.presensi;
          } else {
            target = LoginNavigationTarget.resample;
          }

          _status = LoginStatus.success;
          notifyListeners();

          return LoginResult.success(
            target: target,
            ceklok: ceklok,
            tglKerja: tglKerja,
          );
        } else {
          _status = LoginStatus.error;
          notifyListeners();
          return LoginResult.error(
            'Login Gagal.\nPeriksa Username dan Password Anda.',
          );
        }
      } else if (response.isForbidden) {
        _status = LoginStatus.error;
        notifyListeners();
        return LoginResult.error('Maaf,\nAkses Jaringan Invalid');
      } else {
        _status = LoginStatus.error;
        notifyListeners();
        return LoginResult.error('Maaf,\nKoneksi Server bermasalah.');
      }
    } catch (e) {
      debugPrint('=== LOGIN ERROR ===');
      debugPrint('Error: $e');
      debugPrint('===================');
      _status = LoginStatus.error;
      notifyListeners();
      return LoginResult.error('Maaf,\nKoneksi Server bermasalah.');
    }
  }
}
