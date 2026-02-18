import 'package:flutter/material.dart';

class PresensiProvider extends ChangeNotifier {
  bool _isClockedIn = false;
  String _statusMessage = 'Belum Presensi';
  String? _ceklok;
  String? _tglKerja;

  bool get isClockedIn => _isClockedIn;
  String get statusMessage => _statusMessage;
  String? get ceklok => _ceklok;
  String? get tglKerja => _tglKerja;

  void setData({String? ceklok, String? tglKerja}) {
    _ceklok = ceklok;
    _tglKerja = tglKerja;
    notifyListeners();
  }

  void clockIn() {
    _isClockedIn = true;
    _statusMessage = 'Sudah Presensi';
    notifyListeners();
  }

  void clockOut() {
    _isClockedIn = false;
    _statusMessage = 'Belum Presensi';
    notifyListeners();
  }
}
