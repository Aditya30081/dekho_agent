import 'dart:convert';
import 'package:http/http.dart' as http;

class PublicIpService {
  static String? _cachedIp;

  // Primary IP provider with geo details
  static const String _primaryProvider =
      "https://pro.ip-api.com/json/?fields=query,status,message,continent,countryCode,country,city,region&key=LWKtz4EzQwMJRyQ";

  static const List<String> _ipProviders = [
    "https://api.ipify.org?format=json",
    "https://api64.ipify.org?format=json",
    "https://ifconfig.me/all.json",
    "https://ipapi.co/json/"
  ];

  static Future<String?> getPublicIp() async {
    // Return cached IP if available
    if (_cachedIp != null) {
      return _cachedIp;
    }

    // Try primary provider first
    try {
      final response = await http
          .get(Uri.parse(_primaryProvider))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map &&
            data['status'] == 'success' &&
            data['query'] != null &&
            (data['query'] as String).isNotEmpty) {
          final String ip = data['query'];
          _cachedIp = ip;
          return ip;
        }
      }
    } catch (_) {
      // Ignore and fall back to other providers
    }

    for (final url in _ipProviders) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          String? ip;

          if (data['ip'] != null) {
            ip = data['ip'];
          } else if (data['ip_addr'] != null) {
            ip = data['ip_addr'];
          }

          if (ip != null && ip.isNotEmpty) {
            _cachedIp = ip;
            return ip;
          }
        }
      } catch (_) {
        // Try next provider
      }
    }

    return null;
  }
}