import '../providers/app_config_provider.dart';

class ApiService {
  final AppConfigProvider config;
  static const String baseUrl = 'https://prewa.pnp.ac.id/';

  ApiService(this.config);

  String getEndpoint(String name) {
    final suffix = config.isWfa ? '_global.php' : '.php';
    return '$baseUrl$name$suffix';
  }

  // Helper for specific endpoints if logic differs
  String get loginEndpoint => getEndpoint('login');
  String get pingEndpoint => getEndpoint('ping');
}
