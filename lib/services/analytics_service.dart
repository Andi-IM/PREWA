import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $name, Params: $parameters');
    }
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserId(String? id) async {
    if (kDebugMode) {
      debugPrint('[Analytics] SetUserId: $id');
    }
    await _analytics.setUserId(id: id);
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] SetProperty: $name = $value');
    }
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> logScreenView({
    required String screenName,
    String screenClass = 'Flutter',
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] ScreenView: $screenName');
    }
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> logLogin({String? method}) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Login: $method');
    }
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logLogout() async {
    if (kDebugMode) {
      debugPrint('[Analytics] Logout');
    }
    await _analytics.logEvent(name: 'logout');
  }
}
