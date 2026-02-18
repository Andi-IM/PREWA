import 'package:flutter/material.dart';

class ResampleProvider extends ChangeNotifier {
  String? _ceklok;
  String? _tglKerja;

  String? get ceklok => _ceklok;
  String? get tglKerja => _tglKerja;

  void setData({String? ceklok, String? tglKerja}) {
    _ceklok = ceklok;
    _tglKerja = tglKerja;
    notifyListeners();
  }

  void onProceed() {
    debugPrint('Proceed clicked');
  }

  void onPostpone() {
    debugPrint('Postpone clicked');
  }
}
