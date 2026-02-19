import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/crashlytics_service.dart';

class HomeProvider extends ChangeNotifier {
  ApiService _api;

  String _apiMessage = '';
  String _appVersion = '';
  Timer? _dismissTimer;
  Timer? _versionDismissTimer;
  bool _isDisposed = false;

  String get apiMessage => _apiMessage;
  String get appVersion => _appVersion;

  HomeProvider(this._api);

  void update(ApiService api) {
    _api = api;
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> handleTitleTap() async {
    if (_appVersion.isNotEmpty) {
      _appVersion = '';
      _versionDismissTimer?.cancel();
      _safeNotifyListeners();
      return;
    }

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = 'Versi ${packageInfo.version}';
    } catch (e, stack) {
      _appVersion = 'Versi Unknown';
      CrashlyticsService().recordError(e, stack, reason: 'PackageInfo Error');
    }
    notifyListeners();

    _versionDismissTimer?.cancel();
    _versionDismissTimer = Timer(const Duration(seconds: 2), () {
      _appVersion = '';
      _safeNotifyListeners();
    });
  }

  void handleLogoTap() async {
    if (_apiMessage.isNotEmpty) {
      _apiMessage = '';
      _cancelDismissTimer();
      _safeNotifyListeners();
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
    } catch (e, stack) {
      _apiMessage = 'Connection Error: $e';
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Whoami Connection Error',
      );
    }

    notifyListeners();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _cancelDismissTimer();
    _dismissTimer = Timer(const Duration(seconds: 2), () {
      _apiMessage = '';
      _safeNotifyListeners();
    });
  }

  void _cancelDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelDismissTimer();
    _versionDismissTimer?.cancel();
    super.dispose();
  }
}
