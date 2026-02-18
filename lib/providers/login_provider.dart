import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prewa/services/crashlytics_service.dart';
import 'storage_provider.dart';
import '../services/api_service.dart';
import '../models/login_response.dart';

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
  StorageProvider _storage;
  ApiService _api;

  LoginStatus _status = LoginStatus.idle;
  String? _userId;
  String? _password;
  bool _isDisposed = false;

  LoginProvider(this._storage, this._api);

  LoginStatus get status => _status;
  String? get userId => _userId ?? _storage.userId;
  String? get password => _password ?? _storage.password;

  void update(StorageProvider storage, ApiService api) {
    _storage = storage;
    _api = api;
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void setCredentials(String userId, String password) {
    _userId = userId;
    _password = password;
    _safeNotifyListeners();
  }

  void reset() {
    _status = LoginStatus.idle;
    _safeNotifyListeners();
  }

  Future<LoginResult> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return LoginResult.error('Username dan Password harus diisi');
    }

    _status = LoginStatus.loading;
    _safeNotifyListeners();

    try {
      debugPrint('=== LOGIN REQUEST ===');
      debugPrint('URL: ${_api.baseUrl}${_api.loginEndpoint}');
      debugPrint('Payload: username=$username&password=****');

      final response = await _api.login(username: username, password: password);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('====================');

      if (response.isSuccess && response.loginResponse != null) {
        final loginResponse = response.loginResponse!;

        debugPrint('Parsed Data: ${loginResponse.toLogMap()}');

        if (loginResponse.isSuccess) {
          await _storage.saveCredentials(userId: username, password: password);
          await _storage.saveToken(loginResponse.token ?? '');
          await _storage.saveUserData(
            namaUser: loginResponse.namaUser ?? '',
            sampleId: loginResponse.sampleId ?? '',
          );

          final target = _mapTrainingStatusToTarget(
            loginResponse.trainingStatus,
          );

          _status = LoginStatus.success;
          _safeNotifyListeners();

          return LoginResult.success(
            target: target,
            ceklok: loginResponse.ceklok,
            tglKerja: loginResponse.tglKerja,
          );
        } else {
          _status = LoginStatus.error;
          _safeNotifyListeners();
          return LoginResult.error(
            'Login Gagal.\nPeriksa Username dan Password Anda.',
          );
        }
      } else if (response.isForbidden) {
        _status = LoginStatus.error;
        _safeNotifyListeners();
        return LoginResult.error('Maaf,\nAkses Jaringan Invalid');
      } else {
        _status = LoginStatus.error;
        _safeNotifyListeners();
        return LoginResult.error('Maaf,\nKoneksi Server bermasalah.');
      }
    } on SocketException catch (e) {
      debugPrint('=== LOGIN SOCKET ERROR ===');
      debugPrint('Error: $e');
      debugPrint('==========================');
      _status = LoginStatus.error;
      _safeNotifyListeners();
      return LoginResult.error('Maaf,\nKoneksi internet bermasalah.');
    } on TimeoutException catch (e) {
      debugPrint('=== LOGIN TIMEOUT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('===========================');
      _status = LoginStatus.error;
      _safeNotifyListeners();
      return LoginResult.error('Maaf,\nWaktu koneksi habis.');
    } catch (e, st) {
      debugPrint('=== LOGIN UNKNOWN ERROR ===');
      debugPrint('Error: $e');
      debugPrint('===========================');
      CrashlyticsService().recordError(e, st, reason: 'Login Unknown Error');
      _status = LoginStatus.error;
      _safeNotifyListeners();
      return LoginResult.error('Maaf,\nTerjadi kesalahan internal.');
    }
  }

  LoginNavigationTarget _mapTrainingStatusToTarget(TrainingStatus? status) {
    switch (status) {
      case TrainingStatus.notTrained:
        return LoginNavigationTarget.sampleRecord;
      case TrainingStatus.trained:
        return LoginNavigationTarget.presensi;
      case TrainingStatus.resampleRequired:
      default:
        return LoginNavigationTarget.resample;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
