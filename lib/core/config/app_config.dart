class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: "http://192.168.8.168:8000/api",
  );

  static const String tripMeApiKey = String.fromEnvironment(
    'TRIPME_API_KEY',
    defaultValue: "dev-key-local",
  );

  static const String nodeProxyUrl = String.fromEnvironment(
    'NODE_PROXY_URL',
    defaultValue: "http://10.0.2.2:3000/api",
  );

  static const bool ragEnabled = true;
}
