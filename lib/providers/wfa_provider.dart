import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

enum WfaStatus { initial, loading, success, error }

class WfaProvider extends ChangeNotifier {
  WfaStatus _status = WfaStatus.initial;
  String _message = '';

  WfaStatus get status => _status;
  String get message => _message;

  Future<bool> checkConnection() async {
    _status = WfaStatus.loading;
    _message = "Cek Koneksi Server..";
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('https://prewa.pnp.ac.id/ping_global.php'),
            body: {'get_status': 'ON'},
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _status = WfaStatus.error;
          _message = "Maaf, akses Jaringan Invalid";
          notifyListeners();
          return false;
        }

        try {
          final data = json.decode(response.body);
          // Response format: {"sts_akses":"OK","ip_client":"...","sts_kerja":"OK"}

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
        } catch (e) {
          // JSON parsing error or unexpected format
          _status = WfaStatus.error;
          _message = "Maaf, akses Jaringan Invalid";
          notifyListeners();
          return false;
        }
      } else {
        _status = WfaStatus.error;
        _message =
            "Maaf, akses Jaringan Invalid"; // Server returned error code, treat as invalid network access
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
      _message = "Maaf, \nKoneksi Bermasalah"; // Generic error
      notifyListeners();
      return false;
    }
  }
}
