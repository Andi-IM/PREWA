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

  // Sample Record Endpoints
  static const String uploadFoto = '/upload_foto.php';
  static const String uploadFotoGlobal = '/upload_foto_global.php';
  static const String processTrain = '/process_train.php';
  static const String processTrainGlobal = '/process_train_global.php';
}
