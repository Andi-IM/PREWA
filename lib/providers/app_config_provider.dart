import 'package:flutter/material.dart';
import '../models/app_mode.dart';

class AppConfigProvider extends ChangeNotifier {
  AppMode _mode = AppMode.wfo;

  AppMode get mode => _mode;

  void setMode(AppMode mode) {
    _mode = mode;
    notifyListeners();
  }

  bool get isWfa => _mode == AppMode.wfa;
  bool get isWfo => _mode == AppMode.wfo;
}
