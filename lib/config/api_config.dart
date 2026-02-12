/// API Configuration for managing base URLs across different environments
class ApiConfig {
  // Environment enum
  static const Environment _currentEnvironment = Environment.prod;

  // Base URLs for different environments
  static const String _devBaseUrl = 'https://p2p-backend.unibots.in';
  static const String _prodBaseUrl = 'https://backend.thedekhoapp.com';


  /// Get the current base URL based on environment
  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return _devBaseUrl;
      case Environment.prod:
        return _prodBaseUrl;
    }
  }

  /// Get the external base URL (for terms, privacy policy, etc.)
  static String get externalBaseUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return _devBaseUrl;
      case Environment.prod:
        return _prodBaseUrl;
    }
  }

  /// Get current environment
  static Environment get environment => _currentEnvironment;

  /// Check if current environment is production
  static bool get isProduction => _currentEnvironment == Environment.prod;

  /// Check if current environment is development
  static bool get isDevelopment => _currentEnvironment == Environment.dev;
}

/// Environment enum
enum Environment {
  dev,
  prod,
}

