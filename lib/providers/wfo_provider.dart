import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

enum WfoStatus {
  idle,
  checkingInfrastructure,
  infrastructureError,
  validatingSecurity,
  securityError,
  checkingRestrictions,
  restrictionError,
  redirectToLogin,
}

class WfoProvider extends ChangeNotifier {
  static const String validSsid = 'AINET-5G';

  WfoStatus _status = WfoStatus.idle;
  String _message = '';
  String? _currentSsid;
  String? _currentIp;
  bool _isDisposed = false;

  WfoStatus get status => _status;
  String get message => _message;
  String? get currentSsid => _currentSsid;
  String? get currentIp => _currentIp;

  Future<void> startWfoProcess() async {
    _resetState();
    notifyListeners();

    if (!await _checkWifiConnection()) return;
    if (!await _validateSecurity()) return;
    if (!await _checkWorkingRestrictions()) return;
    _redirectToLogin();
  }

  void _redirectToLogin() {
    _setStatus(WfoStatus.redirectToLogin, "Mengarahkan ke halaman login...");
    notifyListeners();
  }

  Future<bool> _checkWifiConnection() async {
    _setStatus(WfoStatus.checkingInfrastructure, "Memeriksa koneksi WiFi...");
    await Future.delayed(const Duration(seconds: 1));

    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity()
          .checkConnectivity();

      if (!connectivityResult.contains(ConnectivityResult.wifi)) {
        _setStatus(
          WfoStatus.infrastructureError,
          "Harap hubungkan perangkat ke WiFi Kantor.",
        );
        return false;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.locationWhenInUse.status;
        if (!status.isGranted) {
          status = await Permission.locationWhenInUse.request();
        }

        if (!status.isGranted) {
          _setStatus(
            WfoStatus.infrastructureError,
            "Izin lokasi diperlukan untuk memverifikasi WiFi.",
          );
          return false;
        }
      }

      final info = NetworkInfo();
      _currentSsid = await info.getWifiName();

      if (_currentSsid == null) {
        debugPrint(
          "Warning: SSID is null (Location permission might be missing or emulator).",
        );
      } else {
        _currentSsid = _currentSsid!.replaceAll('"', '');
      }

      if (_currentSsid != validSsid && _currentSsid != null) {
        _setStatus(
          WfoStatus.infrastructureError,
          "Terhubung ke $_currentSsid. Harap hubungkan ke $validSsid",
        );
        return false;
      }
      return true;
    } catch (e) {
      _setStatus(WfoStatus.infrastructureError, "Gagal memverifikasi WiFi: $e");
      return false;
    }
  }

  Future<bool> _validateSecurity() async {
    _setStatus(
      WfoStatus.validatingSecurity,
      "Memverifikasi Keamanan Jaringan...",
    );
    await Future.delayed(const Duration(seconds: 1));

    try {
      final info = NetworkInfo();
      _currentIp = await info.getWifiIP();
      final gatewayIp = await info.getWifiGatewayIP();

      _setStatus(
        WfoStatus.validatingSecurity,
        "IP Device: $_currentIp\nIP AP: $gatewayIp",
      );
      await Future.delayed(const Duration(seconds: 1));

      bool isValid = await _validateIp(_currentIp);
      if (!isValid) {
        _setStatus(
          WfoStatus.securityError,
          "Validasi IP Gagal. Akses ditolak.",
        );
        return false;
      }
      return true;
    } catch (e) {
      _setStatus(WfoStatus.securityError, "Gagal validasi keamanan: $e");
      return false;
    }
  }

  Future<bool> _checkWorkingRestrictions() async {
    _setStatus(WfoStatus.checkingRestrictions, "Memeriksa Jam Kerja...");
    await Future.delayed(const Duration(milliseconds: 800));

    if (!_isWithinWorkingHours()) {
      _setStatus(
        WfoStatus.restrictionError,
        "Diluar jam/hari kerja operasional.",
      );
      return false;
    }
    return true;
  }

  bool _isWithinWorkingHours() {
    final now = DateTime.now();

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    if (now.hour < 7 || now.hour >= 18) {
      return false;
    }

    return true;
  }

  Future<bool> _validateIp(String? ip) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (ip == null) return false;
    return ip.startsWith('192.168.') || ip.startsWith('10.');
  }

  void _setStatus(WfoStatus status, String message) {
    if (_isDisposed) return;
    _status = status;
    _message = message;
    notifyListeners();
  }

  void _resetState() {
    _status = WfoStatus.idle;
    _message = '';
    _currentSsid = null;
    _currentIp = null;
  }

  void reset() {
    _resetState();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
