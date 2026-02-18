import 'package:flutter/material.dart';

class PresensiProvider extends ChangeNotifier {
  bool _isClockedIn = false;
  String _statusMessage = 'Belum Presensi';

  bool get isClockedIn => _isClockedIn;
  String get statusMessage => _statusMessage;

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
