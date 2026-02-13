import 'dart:async';
import 'dart:convert';

import 'package:dekho_agent/screens/AgentProfileDetail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/AppColors.dart';
import '../utils/DeviceUtils.dart';
import '../config/api_endpoints.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final String otpDetails;

  const VerificationCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.otpDetails,
  });

  @override
  _VerificationCodeScreenState createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  int _resendTimer = 60; // 1 minute countdown before resend OTP
  Timer? _timer;
  bool _canResend = false;
  static const String _keyChatUserName = 'chatUserName';
  static const String _keyChatPassword = 'chatPassword';
  static const String _keyChatToken = 'chatToken';
  static const String _keyUserToken = 'userToken';
  static const String _keyFirebaseCustomToken = 'firebaseCustomToken';

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Add listeners to all controllers
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(_updateButtonState);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _canResend = false;
    _resendTimer = 60;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _otpControllers.every((controller) => controller.text.isNotEmpty);
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _clearOtpFields() {
    if (!mounted) return;
    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _isButtonEnabled = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });
    final deviceId = await DeviceUtils.fetchAndSaveDeviceId();
    try {
      print("RESEND OTP REQUEST:");
      print("URL: ${ApiEndpoints.sendOtpUrl}");
      print("Body: ${jsonEncode({
        'mobileNumber': widget.phoneNumber,
        'role': 'agent',
        'deviceId': deviceId,
      })}");

      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': widget.phoneNumber,
          'role': 'agent',
          'deviceId': deviceId,
        }),
      );

      print('RESEND OTP API Response Status: ${response.statusCode}');
      print('RESEND OTP API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'OTP sent successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        _startTimer();

        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        print('RESEND OTP API Error - Status Code: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('RESEND OTP API Error Response: $errorData');
        } catch (e) {
          print('RESEND OTP API Error parsing response: $e');
        }
        Fluttertoast.showToast(
          msg: 'Unable to send OTP',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print('RESEND OTP API Exception: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpCode();

    // Validate OTP length
    if (otp.length != 6) {
      Fluttertoast.showToast(
        msg: 'Please enter 6 digit OTP',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      //final AuthService _authService = AuthService();
      final deviceId = await DeviceUtils.fetchAndSaveDeviceId();
      final deviceName = await DeviceUtils.getDeviceName();
      final appVersion = await DeviceUtils.getAppVersion();

      //String? fcmToken;
      //final cachedToken = await _authService.getFirebaseCustomToken();

     /* if (cachedToken == null || cachedToken.isEmpty) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken().timeout(
            Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ FCM token fetch timed out');
              return null;
            },
          );

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await AuthService().saveFcmToken(fcmToken);
            print('✅ FCM token fetched successfully');
          }
        } catch (e) {
          print('❌ Error fetching FCM token: $e');
          fcmToken = null;
        }
      }
      else {
        fcmToken = cachedToken;
        print('✅ Using cached FCM token');
      }*/

      final requestBody = {
        'mobileNumber': widget.phoneNumber,
        'otp': otp,
        //'fcmToken': fcmToken,
        'deviceId': deviceId,
        'otpDetails': widget.otpDetails,
        // 'deviceName': deviceName,
        // 'appVersion': appVersion,
        'role': 'agent',
      };

// 👇 Print nicely formatted JSON
      print("VERIFY OTP REQUEST BODY:");
      print(const JsonEncoder.withIndent('  ').convert(requestBody));

      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('VERIFY OTP API Response Status: ${response.statusCode}');
      print('VERIFY OTP API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('VERIFY OTP Response Data: $responseData');
        print('📋 VERIFY OTP Response Structure Check:');
        print('   - responseData keys: ${responseData.keys}');
        print('   - responseData["data"]: ${responseData['data']}');
        if (responseData['data'] != null) {
          print('   - responseData["data"] keys: ${responseData['data'].keys}');
        }

        // Save all values to SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // Try different possible response structures
        final sessionToken = responseData['data']?['sessionToken'] ?? 
                            responseData['sessionToken'] ?? 
                            responseData['data']?['token'] ??
                            responseData['token'];
        final userId = responseData['data']?['userId'] ?? responseData['userId'];
        final userName = responseData['data']?['name'] ?? responseData['name'];
        
        print('🔑 Extracted sessionToken: ${sessionToken != null ? "Found (${sessionToken.length} chars)" : "NULL"}');
        print('👤 Extracted userId: ${userId ?? "NULL"}');
        print('📝 Extracted userName: ${userName ?? "NULL"}');
        // final userGender = responseData['data']?['user']?['gender'];
        // final userRole = responseData['data']?['user']?['role'];
        // final chatUserName = responseData['data']?['agora']?['chatUserName'] ?? '';
        // final chatPassword = responseData['data']?['agora']?['chatPassword'] ?? '';
        // final appToken = responseData['data']?['agora']?['appToken'] ?? '';
        // final chatUserToken = responseData['data']?['agora']?['chatUserToken'] ?? '';
        // final fireBaseCustomToken = responseData['data']?['fireBaseCustomToken'] ?? '';


        // Save to SharedPreferences - await ensures save completes
        if (sessionToken != null && sessionToken.toString().isNotEmpty) {
          final tokenSaved = await prefs.setString('sessionToken', sessionToken.toString());
          print('✅ Session Token save operation result: $tokenSaved');
          print('✅ Session Token saved to SharedPreferences: ${sessionToken.toString().substring(0, sessionToken.toString().length > 20 ? 20 : sessionToken.toString().length)}...');
          
          // Verify the save was successful by reading it back
          final savedToken = await Future.value(prefs.getString('sessionToken'));
          if (savedToken != null && savedToken == sessionToken.toString()) {
            print('✅ Verification: SessionToken confirmed saved correctly (${savedToken.length} chars)');
          } else {
            print('⚠️ WARNING: SessionToken save verification failed - token may not be persisted');
            print('   Expected: ${sessionToken.toString().substring(0, sessionToken.toString().length > 50 ? 50 : sessionToken.toString().length)}...');
            print('   Got: ${savedToken != null ? savedToken.substring(0, savedToken.length > 50 ? 50 : savedToken.length) : "NULL"}...');
          }
        } else {
          print('❌ ERROR: sessionToken is NULL or empty - NOT SAVED!');
          print('   Response structure: ${responseData.toString()}');
        }
        
        if (userId != null) {
          await prefs.setString('userId', userId.toString());
          print('✅ User ID saved to SharedPreferences: $userId');
        } else {
          print('⚠️ User ID is NULL - NOT SAVED');
        }
        
        if (userName != null) {
          await prefs.setString('user_name', userName.toString());
          print('✅ User Name saved to SharedPreferences: $userName');
        }
        
        // Save mobile number for profile updates
        await prefs.setString('mobileNumber', widget.phoneNumber);
        print('✅ Mobile Number saved to SharedPreferences: ${widget.phoneNumber}');
        
        // Final verification - get all keys to see what's stored
        final allKeys = await Future.value(prefs.getKeys());
        print('📋 All SharedPreferences keys after save: $allKeys');
        final finalTokenCheck = await Future.value(prefs.getString('sessionToken'));
        print('🔍 Final token check before navigation: ${finalTokenCheck != null ? "EXISTS (${finalTokenCheck.length} chars)" : "MISSING!"}');
        // if (chatUserName != null) await prefs.setString(_keyChatUserName, chatUserName);
        // if (chatPassword != null) await prefs.setString(_keyChatPassword, chatPassword);
        // if (appToken != null) await prefs.setString(_keyChatToken, appToken);
        // if (chatUserToken != null) await prefs.setString(_keyUserToken, chatUserToken);
        // if (fireBaseCustomToken != null) {
        //   await prefs.setString(_keyFirebaseCustomToken, fireBaseCustomToken);
        // }

        // print("chatLogin data : " +
        //     "chatUserName: $chatUserName, " +
        //     "chatUserToken: $chatUserToken, " +
        //     "chatPassword: $chatPassword"
        // );
        // // final chatPassword = await authService.getChatPassword();
        // await ChatService().login(
        //   chatUserName,
        //   token: chatUserToken,
        //   password: chatPassword, // Provide password as fallback
        // );
        
        // Connect to socket after successful OTP verification
        // print('=== INITIALIZING SOCKET CONNECTION AFTER OTP VERIFICATION ===');
        // bool socketConnected = false;
        // int retryCount = 0;
        // const maxRetries = 3;
        
        // while (!socketConnected && retryCount < maxRetries) {
        //   try {
        //     await SocketService().connect(timeout: const Duration(seconds: 8));
        //     socketConnected = SocketService().isConnected;
        //
        //     if (socketConnected) {
        //       print('✅ Socket connected successfully on attempt ${retryCount + 1}');
        //     } else {
        //       print('⚠️ Socket connection initiated but not confirmed');
        //     }
        //     break; // Exit retry loop on success
        //   } catch (e) {
        //     retryCount++;
        //     print('❌ Socket connection attempt ${retryCount} failed: $e');
        //
        //     if (retryCount < maxRetries) {
        //       print('🔄 Retrying socket connection in 2 seconds...');
        //       await Future.delayed(const Duration(seconds: 2));
        //     } else {
        //       print('❌ Socket connection failed after $maxRetries attempts');
        //       print('⚠️ Continuing navigation without socket connection');
        //     }
        //   }
        // }
        //
        // // Verify final connection status
        // if (SocketService().isConnected) {
        //   print('✅ Socket is confirmed connected');
        // } else {
        //   print('⚠️ Socket connection status: ${SocketService().isConnected}');
        // }
        
        // if (mobileNumber != null) await prefs.setString('mobile_number', mobileNumber);
        // if (email != null) await prefs.setString('email_id', email);
        // if (userGender != null && userGender != 'Prefer Not To Say') {
        //   await prefs.setString('gender', userGender);
        // }
        // if (userRole != null) await prefs.setString('role', userRole);
        
        // Set profileSetupCompleted flag
        // Use API response value if available, otherwise default to false
        // final isProfileComplete = profileSetupComplete ?? false;
        // await prefs.setBool('profileSetupCompleted', isProfileComplete);
        // print('✅ profileSetupCompleted flag set to: $isProfileComplete');
        // print('✅ User role: $userRole');
        
        // if (linkedInVerified != null) await prefs.setBool('linkedInVerified', linkedInVerified);
        // if (profile60Completed != null) await prefs.setBool('profile60Completed', profile60Completed);
        // if (linkedinLoginStatus != null) await prefs.setBool('linkedinLoginStatus', linkedinLoginStatus);

        // print('✅ Session Token: $sessionToken');
        // print('✅ User ID: $userId');
        // print('✅ All values saved to SharedPreferences');

        Fluttertoast.showToast(
          msg: 'OTP Verified Successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Navigate based on internal profileSetupCompleted flag
        // Check SharedPreferences for the flag (we just saved it above)
        final isProfileCompleted = prefs.getBool('profileSetupCompleted') ?? false;
        
        print('🔍 Navigation Decision: isProfileComplete = $isProfileCompleted');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AgentProfileDetail()),
        );
        
      } else {
        print('VERIFY OTP API Error - Status Code: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        print('VERIFY OTP API Error Response: $errorData');
        final errorMessage = errorData['message'] ?? 'OTP Verification Failed';
        
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        if (mounted) _clearOtpFields();
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      Fluttertoast.showToast(
        msg: 'Error verifying OTP: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      if (mounted) _clearOtpFields();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: 32),
              // Title
              Text(
                "Mobile verification has successfully done",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 12),
              // Description with phone number
              Text(
                "We have send the OTP on ${widget.phoneNumber} will apply auto to the fields",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 40),
              // OTP Input fields (digit above reddish-orange underline)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (index) {
                    const underlineColor = Color(0xFFE85D2A);
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 36,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                                fontFamily: 'Inter',
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                hintText: '_',
                                hintStyle: TextStyle(
                                  fontSize: 26,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onTap: () {
                                // When user taps on a field, select all text so they can easily replace it
                                _otpControllers[index].selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _otpControllers[index].text.length,
                                );
                              },
                              onChanged: (value) {
                                // If user enters a digit, move to next field
                                if (value.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } 
                                // If user deletes and field becomes empty, move to previous field
                                else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                // Update button state
                                _updateButtonState();
                              },
                            ),
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: underlineColor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 32),
              // Resend: "If you didn't receive a code! Resend"
              GestureDetector(
                onTap: _canResend ? _resendOtp : null,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: "If you didn't receive a code! ",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextSpan(
                        text: _canResend
                            ? 'Resend'
                            : 'Resend (${_resendTimer}s)',
                        style: TextStyle(
                          color: Color(0xFFE85D2A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              // Verify button (capsule, reddish-orange)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonEnabled
                        ? Color(0xFFE85D2A)
                        : Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? _verifyOtp
                      : null,
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Verify",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _isButtonEnabled
                                ? Colors.white
                                : Colors.grey.shade500,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
