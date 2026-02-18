import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

enum WfaStatus { initial, loading, success, error }

class WfaProvider extends ChangeNotifier {
  ApiService _api;

  WfaStatus _status = WfaStatus.initial;
  String _message = '';
  bool _isDisposed = false;

  WfaProvider(this._api);

  WfaStatus get status => _status;
  String get message => _message;

  void updateApi(ApiService api) {
    _api = api;
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<bool> checkConnection() async {
    _status = WfaStatus.loading;
    _message = "Cek Koneksi Server..";
    _safeNotifyListeners();

    try {
      final response = await _api.ping();

      if (response.isSuccess && response.pingResponse != null) {
        final pingResponse = response.pingResponse!;

        if (pingResponse.isWfaDisabled) {
          _status = WfaStatus.error;
          _message = "Maaf, Status WFA Non-Aktif";
          _safeNotifyListeners();
          return false;
        }

        if (pingResponse.isNotWorkingDay) {
          _status = WfaStatus.error;
          _message = "Maaf, Bukan Hari Kerja";
          _safeNotifyListeners();
          return false;
        }

        if (pingResponse.isValid) {
          _status = WfaStatus.success;
          _message = "Selamat Datang di \n PREWA PNP";
          _safeNotifyListeners();
          return true;
        } else {
          _status = WfaStatus.error;
          _message = "Maaf, akses Jaringan Invalid";
          _safeNotifyListeners();
          return false;
        }
      } else {
        _status = WfaStatus.error;
        _message = "Maaf, akses Jaringan Invalid";
        _safeNotifyListeners();
        return false;
      }
    } on TimeoutException catch (_) {
      _status = WfaStatus.error;
      _message = "Maaf, \nKoneksi Bermasalah";
      _safeNotifyListeners();
      return false;
    } catch (e) {
      _status = WfaStatus.error;
      _message = "Maaf, \nKoneksi Bermasalah";
      _safeNotifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
