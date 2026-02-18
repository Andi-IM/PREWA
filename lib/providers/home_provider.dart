import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import '../services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _api;

  String _apiMessage = '';
  String _appVersion = '';
  Timer? _dismissTimer;
  Timer? _versionDismissTimer;

  String get apiMessage => _apiMessage;
  String get appVersion => _appVersion;

  HomeProvider(this._api);

  Future<void> handleTitleTap() async {
    if (_appVersion.isNotEmpty) {
      _appVersion = '';
      _versionDismissTimer?.cancel();
      notifyListeners();
      return;
    }

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = 'Versi ${packageInfo.version}';
    } catch (e) {
      _appVersion = 'Versi Unknown';
    }
    notifyListeners();

    _versionDismissTimer?.cancel();
    _versionDismissTimer = Timer(const Duration(seconds: 2), () {
      _appVersion = '';
      notifyListeners();
    });
  }

  void handleLogoTap() async {
    if (_apiMessage.isNotEmpty) {
      _apiMessage = '';
      _cancelDismissTimer();
      notifyListeners();
      return;
    }

    _apiMessage = 'Checking connection...';
    notifyListeners();

    try {
      final response = await _api.whoami();

      if (response.isSuccess) {
        _apiMessage = response.body;
      } else {
        _apiMessage = 'Error: ${response.statusCode}';
      }
    } on TimeoutException catch (_) {
      _apiMessage = 'Koneksi Server Bermasalah (1103)';
    } catch (e) {
      _apiMessage = 'Connection Error: $e';
    }

    notifyListeners();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _cancelDismissTimer();
    _dismissTimer = Timer(const Duration(seconds: 2), () {
      _apiMessage = '';
      notifyListeners();
    });
  }

  void _cancelDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  @override
  void dispose() {
    _cancelDismissTimer();
    _versionDismissTimer?.cancel();
    super.dispose();
  }
}
