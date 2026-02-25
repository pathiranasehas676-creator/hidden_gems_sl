class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: "http://192.168.8.168:8000/api",
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: "dev-key-local",
  );

  static const bool ragEnabled = true;
}
