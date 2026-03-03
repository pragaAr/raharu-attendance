import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _defaultLanUrl = 'http://192.168.3.11:8000/api';
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _lanUrlOverride = String.fromEnvironment('API_LAN_URL');

  static String get lanUrl =>
      _lanUrlOverride.isNotEmpty ? _lanUrlOverride : _defaultLanUrl;

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    if (kIsWeb) {
      return lanUrl;
    }
    if (Platform.isAndroid) {
      // return 'http://10.0.2.2:8000/api';
      return lanUrl;
    }
    // return 'http://127.0.0.1:8000/api';
    return lanUrl;
  }

  static List<String> get fallbackBaseUrls {
    if (_baseUrlOverride.isNotEmpty) {
      return [_baseUrlOverride];
    }

    if (kIsWeb) {
      return [lanUrl];
    }

    if (Platform.isAndroid) {
      return ['http://10.0.2.2:8000/api', lanUrl];
    }

    return ['http://127.0.0.1:8000/api', lanUrl];
  }
}
