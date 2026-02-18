class ApiConfig {
  static const String baseUrl = 'https://prewa.pnp.ac.id';

  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 2);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };
}

class ApiEndpoints {
  static const String login = '/login.php';
  static const String loginGlobal = '/login_global.php';
  static const String ping = '/ping.php';
  static const String pingGlobal = '/ping_global.php';
  static const String whoami = '/whoami.php';
}
