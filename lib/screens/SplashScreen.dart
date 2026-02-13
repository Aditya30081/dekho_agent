import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/AppColors.dart';
import '../config/api_endpoints.dart';
import 'CreateInfluencerLink.dart';
import 'LoginScreen.dart';
import 'AgentProfileDetail.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    try {
      print('🔐 JWT VERIFICATION: Starting session check...');
      
      // Get session token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sessionTokenRaw = prefs.getString('sessionToken');

      if (sessionTokenRaw == null || sessionTokenRaw.isEmpty) {
        print('❌ JWT VERIFICATION: No session token found in SharedPreferences');
        print('   → Navigating to LoginScreen');
        // No session token found, navigate to login
        _navigateToLogin();
        return;
      }

      // Trim token to remove any whitespace
      final sessionToken = sessionTokenRaw.trim();

      print('✅ JWT VERIFICATION: Session token found');
      print('   Token length: ${sessionToken.length} characters');
      print('   Token preview: ${sessionToken.substring(0, sessionToken.length > 20 ? 20 : sessionToken.length)}...');
      print('   Token ends with: ...${sessionToken.length > 20 ? sessionToken.substring(sessionToken.length - 20) : sessionToken}');

      final apiUrl = ApiEndpoints.sessionLoginUrl;
      print('📡 JWT VERIFICATION: Making POST request');
      print('   URL: $apiUrl');
      
      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionToken',
      };
      
      // Some APIs require an empty JSON body for POST requests with Content-Type: application/json
      // If this doesn't work, try removing the body parameter: body: jsonEncode({})
      final requestBody = jsonEncode(<String, dynamic>{});
      
      print('   Headers: {Content-Type: application/json, Authorization: Bearer ***}');
      print('   Authorization Header Value: Bearer ${sessionToken.substring(0, sessionToken.length > 50 ? 50 : sessionToken.length)}...');
      print('   Request Body: $requestBody');

      // Make POST API call to session-login endpoint
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: requestBody,
      );

      print('📥 JWT VERIFICATION: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Response Headers: ${response.headers}');
      print('   Response Body Length: ${response.body.length} characters');
      print('   Response Body:');
      print('   ${response.body}');

      // Check if response is successful (200 or 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ JWT VERIFICATION: HTTP Status indicates success (${response.statusCode})');
        
        try {
          final responseData = jsonDecode(response.body);
          print('✅ JWT VERIFICATION: Response parsed successfully');
          print('   Parsed Response Data:');
          print('   ${const JsonEncoder.withIndent('     ').convert(responseData)}');
          
          // Check if response indicates success
          final isSuccess = responseData['success'] == true || response.statusCode == 200;
          print('   Success flag: ${responseData['success']}');
          print('   Final verification result: $isSuccess');
          
          if (isSuccess) {
            // Extract profileCompleted from response
            final data = responseData['data'] ?? responseData;
            final profileCompleted = data['profileCompleted'] ?? responseData['profileCompleted'] ?? false;
            
            print('✅ JWT VERIFICATION: Session is valid');
            print('   Profile Completed: $profileCompleted');
            
            if (profileCompleted == true) {
              print('   → Navigating to CreateInfluencerLink (profile completed)');
              _navigateToCreateInfluencerLink();
            } else {
              print('   → Navigating to AgentProfileDetail (profile not completed)');
              _navigateToAgentProfileDetail();
            }
          } else {
            print('❌ JWT VERIFICATION: Session validation failed (success flag is false)');
            print('   → Navigating to LoginScreen');
            // Session invalid, navigate to login
            _navigateToLogin();
          }
        } catch (e) {
          print('⚠️ JWT VERIFICATION: Error parsing response JSON');
          print('   Error: $e');
          print('   Raw response body: ${response.body}');
          
          // If status is 200/201, treat as success even if parsing fails
          if (response.statusCode == 200 || response.statusCode == 201) {
            print('✅ JWT VERIFICATION: Treating as success (HTTP ${response.statusCode} despite parse error)');
            print('   → Navigating to CreateInfluencerLink (default, parse error)');
            _navigateToCreateInfluencerLink();
          } else {
            print('❌ JWT VERIFICATION: Parse error and non-success status');
            print('   → Navigating to LoginScreen');
            _navigateToLogin();
          }
        }
      } else {
        print('❌ JWT VERIFICATION: HTTP Status indicates failure (${response.statusCode})');
        print('   → Navigating to LoginScreen');
        
        // Try to parse error response for additional info
        try {
          final errorData = jsonDecode(response.body);
          print('   Error Response Data:');
          print('   ${const JsonEncoder.withIndent('     ').convert(errorData)}');
          if (errorData['message'] != null) {
            print('   Error Message: ${errorData['message']}');
          }
        } catch (e) {
          print('   Could not parse error response: $e');
        }
        
        // API call failed, navigate to login
        _navigateToLogin();
      }
    } catch (e, stackTrace) {
      print('❌ JWT VERIFICATION: Exception occurred');
      print('   Error: $e');
      print('   Stack Trace: $stackTrace');
      print('   → Navigating to LoginScreen');
      // On error, navigate to login
      _navigateToLogin();
    }
  }

  void _navigateToCreateInfluencerLink() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateInfluencerLink()),
        );
      }
    });
  }

  void _navigateToAgentProfileDetail() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AgentProfileDetail()),
        );
      }
    });
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/small_logo.png",
              height: 80,
              width: 88,
            ),
            const SizedBox(height: 20),
            const Text(
              'Dekho',
              style: TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.w200,
                fontFamily: 'Lexend',
                color: AppColors.backgroundColor,
                letterSpacing: -3.6,
              ),
            ),
            const Text(
              'Magar Pyaar se',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.backgroundColor,
                fontFamily: 'Lexend',
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.backgroundColor),
            ),
          ],
        ),
      ),
    );
  }
}

