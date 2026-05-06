/// API Configuration for managing base URLs across different environments
class ApiConfig {
  // Environment enum
  static const Environment _currentEnvironment = Environment.staging;

  // Base URLs for different environments
  static const String _devBaseUrl = 'https://p2p-backend-dev.thedekhoapp.com';
  static const String _prodBaseUrl = 'https://backend.thedekhoapp.com';
  static const String _stagingBaseUrl = 'https://p2p-backend-staging.thedekhoapp.com';

  // Apk download URLs and file names for different environments
  static const String _devApkDownloadUrl =
      'https://p2pbackend.b-cdn.net/apk/agent/Master_Dekho_Agent_dev.apk';
  static const String _prodApkDownloadUrl =
      'https://p2pbackend.b-cdn.net/apk/agent/Master_Dekho_Agent.apk';
  static const String _stagingApkDownloadUrl =
      'https://p2pbackend.b-cdn.net/apk/agent/Master_Dekho_Agent_staging.apk';

  static const String _devApkFileName = 'Master_Dekho_Agent_dev.apk';
  static const String _stagingApkFileName = 'Master_Dekho_Agent_staging.apk';
  static const String _prodApkFileName = 'Master_Dekho_Agent.apk';


  /// Get the current base URL based on environment
  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return _devBaseUrl;
      case Environment.prod:
        return _prodBaseUrl;
      case Environment.staging:
        return _stagingBaseUrl;
    }
  }

  /// Get the external base URL (for terms, privacy policy, etc.)
  static String get externalBaseUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return _devBaseUrl;
      case Environment.prod:
        return _prodBaseUrl;
      case Environment.staging:
        return _stagingBaseUrl;
    }
  }

  /// Get current environment
  static Environment get environment => _currentEnvironment;

  /// Check if current environment is production
  static bool get isProduction => _currentEnvironment == Environment.prod;

  /// Check if current environment is development
  static bool get isDevelopment => _currentEnvironment == Environment.dev;

  /// Check if current environment is staging
  static bool get isStaging => _currentEnvironment == Environment.staging;

  /// Get APK download URL based on selected environment
  static String get apkDownloadUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return _devApkDownloadUrl;
      case Environment.prod:
        return _prodApkDownloadUrl;
      case Environment.staging:
        return _stagingApkDownloadUrl;
    }
  }

  /// Get APK file name based on selected environment
  static String get apkFileName {
    switch (_currentEnvironment) {
      case Environment.dev:
        return _devApkFileName;
      case Environment.prod:
        return _prodApkFileName;
      case Environment.staging:
        return _stagingApkFileName;
    }
  }
}

/// Environment enum
enum Environment {
  dev,
  prod,
  staging
}

