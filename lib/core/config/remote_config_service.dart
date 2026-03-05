import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../core/utils/secure_logger.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  static RemoteConfigService? _instance;

  static Future<RemoteConfigService> getInstance() async {
    if (_instance == null) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      _instance = RemoteConfigService(remoteConfig);
    }
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.setDefaults({
        'api_version': '1.0.0',
        'model_name': 'gemini-1.5-flash',
        'is_rag_enabled': true,
        'theme_config': 'default',
        'data_refresh_timestamp': 0,
      });

      await fetchAndActivate();
    } catch (e) {
      SecureLogger.error('RemoteConfig initialization failed', e);
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      SecureLogger.error('RemoteConfig fetch failed', e);
    }
  }

  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);

  // Specific helpers
  String get apiVersion => getString('api_version');
  String get modelName => getString('model_name');
  bool get isRagEnabled => getBool('is_rag_enabled');
  String get themeConfig => getString('theme_config');
  int get dataRefreshTimestamp => getInt('data_refresh_timestamp');
}
