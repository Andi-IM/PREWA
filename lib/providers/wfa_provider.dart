import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

enum WfaStatus { initial, loading, success, error }

class WfaProvider extends ChangeNotifier {
  final ApiService _api;

  WfaStatus _status = WfaStatus.initial;
  String _message = '';

  WfaProvider(this._api);

  WfaStatus get status => _status;
  String get message => _message;

  Future<bool> checkConnection() async {
    _status = WfaStatus.loading;
    _message = "Cek Koneksi Server..";
    notifyListeners();

    try {
      final response = await _api.ping();

      if (response.isSuccess && response.hasData) {
        final data = response.data!;

        if (!data.containsKey('sts_akses')) {
          _status = WfaStatus.error;
          _message = "Maaf, akses Jaringan Invalid";
          notifyListeners();
          return false;
        }

        final stsAkses = data['sts_akses'];

        if (stsAkses == 'NO_WFA') {
          _status = WfaStatus.error;
          _message = "Maaf, Status WFA Non-Aktif";
          notifyListeners();
          return false;
        }

        if (!data.containsKey('sts_kerja')) {
          _status = WfaStatus.error;
          _message = "Maaf, Bukan Hari Kerja";
          notifyListeners();
          return false;
        }

        final stsKerja = data['sts_kerja'];

        if (stsAkses == 'OK' && stsKerja == 'OK') {
          _status = WfaStatus.success;
          _message = "Selamat Datang di \n PREWA PNP";
          notifyListeners();
          return true;
        } else {
          _status = WfaStatus.error;
          _message = "Maaf, akses Jaringan Invalid";
          notifyListeners();
          return false;
        }
      } else {
        _status = WfaStatus.error;
        _message = "Maaf, akses Jaringan Invalid";
        notifyListeners();
        return false;
      }
    } on TimeoutException catch (_) {
      _status = WfaStatus.error;
      _message = "Maaf, \nKoneksi Bermasalah";
      notifyListeners();
      return false;
    } catch (e) {
      _status = WfaStatus.error;
      _message = "Maaf, \nKoneksi Bermasalah";
      notifyListeners();
      return false;
    }
  }
}
