import 'package:flutter/material.dart';

class AppConfigProvider extends ChangeNotifier {
  bool _isWfa = false;

  bool get isWfa => _isWfa;

  void setWfa(bool value) {
    _isWfa = value;
    notifyListeners();
  }
}
