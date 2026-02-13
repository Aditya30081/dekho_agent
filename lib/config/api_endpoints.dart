import 'api_config.dart';

/// Centralized API endpoints
/// All endpoints are relative paths that will be combined with base URL
class ApiEndpoints {
  // Auth endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String sessionLogin = '/auth/session-login';

  // Agent endpoints
  static const String updateProfile = '/api/agent/updateProfile';
  static const String getProfile = '/api/agent/getProfile';

  // External URLs (terms, privacy policy, etc.)
  static const String termsOfUse = '/terms/';
  static const String privacyPolicy = '/privacy-policy/';

  /// Get full URL for an API endpoint
  static String getApiUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  /// Get full URL for an external endpoint (terms, privacy, etc.)
  static String getExternalUrl(String endpoint) {
    return '${ApiConfig.externalBaseUrl}$endpoint';
  }

  // Convenience methods for commonly used endpoints
  static String get sendOtpUrl => getApiUrl(sendOtp);
  static String get verifyOtpUrl => getApiUrl(verifyOtp);
  static String get sessionLoginUrl => getApiUrl(sessionLogin);
  static String get updateProfileUrl => getApiUrl(updateProfile);
  static String get getProfileUrl => getApiUrl(getProfile);
  static String get termsOfUseUrl => getExternalUrl(termsOfUse);
  static String get privacyPolicyUrl => getExternalUrl(privacyPolicy);
}

