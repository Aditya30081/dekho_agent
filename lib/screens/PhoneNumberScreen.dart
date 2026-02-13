import 'dart:convert';
import 'dart:ffi';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../constants/AppColors.dart';

import '../utils/DeviceUtils.dart';
import '../config/api_endpoints.dart';
import 'VerificationCodeScreen.dart';

class PhoneNumberScreen extends StatefulWidget {
  final String? phoneNumber;
  final bool? numberEdited;


  const PhoneNumberScreen({super.key,  this.phoneNumber, this.numberEdited, /*required this.existingUser*/});

  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  String _phoneNumber = '';
  int _maxLength = 10; // Default for India
  bool _isButtonEnabled = false;
  bool _isLoading = false; // Loading state for API call
  // Add a new variable to store the local number
  String _localNumber = '';
  // Add a key to force widget rebuild when country changes
  // Add a controller to manage the text field
  final TextEditingController _phoneController = TextEditingController();
  // Full E.164 country calling codes (as of 2025)
  List<String> countryCodes = [
    // North America
    "+1", // USA, Canada, Caribbean

    // Europe
    "+20", "+27", "+30", "+31", "+32", "+33", "+34", "+36", "+39",
    "+40", "+41", "+43", "+44", "+45", "+46", "+47", "+48", "+49",
    "+350", "+351", "+352", "+353", "+354", "+355", "+356", "+357", "+358", "+359",
    "+370", "+371", "+372", "+373", "+374", "+375", "+376", "+377", "+378", "+379",
    "+380", "+381", "+382", "+383", "+385", "+386", "+387", "+389",
    "+420", "+421", "+423",

    // Russia & Central Asia
    "+7", "+76", "+77", // Russia, Kazakhstan

    // Middle East
    "+90", "+91", "+92", "+93", "+94", "+95", "+96", "+98",
    "+970", "+971", "+972", "+973", "+974", "+975", "+976", "+977", "+979",

    // Africa
    "+211", "+212", "+213", "+216", "+218",
    "+220", "+221", "+222", "+223", "+224", "+225", "+226", "+227", "+228", "+229",
    "+230", "+231", "+232", "+233", "+234", "+235", "+236", "+237", "+238", "+239",
    "+240", "+241", "+242", "+243", "+244", "+245", "+246", "+247", "+248", "+249",
    "+250", "+251", "+252", "+253", "+254", "+255", "+256", "+257", "+258", "+260",
    "+261", "+262", "+263", "+264", "+265", "+266", "+267", "+268", "+269",
    "+290", "+291", "+297", "+298", "+299",

    // Asia
    "+60", "+61", "+62", "+63", "+64", "+65", "+66",
    "+81", "+82", "+84", "+86", "+852", "+853", "+855", "+856", "+880", "+886",

    // Oceania & Pacific
    "+670", "+672", "+673", "+674", "+675", "+676", "+677", "+678", "+679",
    "+680", "+681", "+682", "+683", "+685", "+686", "+687", "+688", "+689",
    "+690", "+691", "+692",

    // Caribbean (under +1, but some separate codes too)
    "+1242", "+1246", "+1264", "+1268", "+1284", "+1340", "+1345",
    "+1441", "+1473", "+1649", "+1664", "+1670", "+1671", "+1684",
    "+1758", "+1767", "+1784", "+1787", "+1809", "+1868", "+1869", "+1876",

    // South America
    "+500", "+501", "+502", "+503", "+504", "+505", "+506", "+507", "+508", "+509",
    "+51", "+52", "+53", "+54", "+55", "+56", "+57", "+58", "+591", "+592", "+593",
    "+594", "+595", "+596", "+597", "+598", "+599",

    // Antarctica & special
    "+672", "+881", "+882", "+883", "+888", "+979", "+991", "+992", "+993", "+994", "+995", "+996", "+998",
  ];


  @override
  void initState() {
    super.initState();

    if (widget.numberEdited == true && widget.phoneNumber != null) {
      _phoneNumber = widget.phoneNumber!;
      _phoneController.text = removeCountryCode(_phoneNumber);
      // _phoneController.text = _phoneNumber;
      //_phoneController.text = _phoneNumber.replaceFirst(RegExp(r'^\+\d+\s*'), '');
    }
    _updateButtonState();

  }

  String removeCountryCode(String phoneNumber) {
    for (final code in countryCodes..sort((a, b) => b.length.compareTo(a.length))) {
      if (phoneNumber.startsWith(code)) {
        return phoneNumber.substring(code.length);
      }
    }
    return phoneNumber; // fallback (if no match)
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _localNumber.length == _maxLength;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60),
                  // Decorative icons section
                  Stack(
                    alignment: Alignment.center,
              children: [
                      // Center circle background
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Orange wallet icon in center
                Image.asset('assets/wallet.png', width: 60, height: 60),
                      // Green circle - top right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Image.asset('assets/green_tick.png', width: 40, height: 40)
                      ),
                      // Yellow circle - bottom left
                      Positioned(
                        bottom: -5,
                        left: 20,
                          child: Image.asset('assets/coins.png', width: 40, height: 40)
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  // Title
                  Text(
                    "Secure Your",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.backgroundColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  // Subtitle
                  Text(
                    "Earnings & Stats",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B2C),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 4),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Link your phone number to save your live stream history, gifts and payout details permanently",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  // Phone number label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "PHONE NUMBER",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.backgroundColor,
                        fontFamily: 'Inter',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Phone number input field
                  Container(
                    height: 56,
                              decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Flag and country code
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              // India flag
                              Container(
                                width: 32,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.asset(
                                    'assets/flags/in.png',
                                    width: 32,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to emoji flag if asset not found
                                      return Text(
                                        '🇮🇳',
                                        style: TextStyle(fontSize: 20),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '+91',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Phone number input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontFamily: 'Inter',
                              letterSpacing: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Phone Number',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                                fontFamily: 'Inter',
                                letterSpacing: 1.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_maxLength),
                            ],
                            onChanged: (value) {
                              _phoneNumber = '+91$value';
                              _localNumber = value;
                              _updateButtonState();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled ? Color(0xFFFF6B2C) : Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    onPressed: (_isButtonEnabled && !_isLoading) ? () async {
                      // Check internet connectivity before sending OTP
                     /* final connectivityResult = await Connectivity().checkConnectivity();
                      // Handle both List<ConnectivityResult> (newer versions) and ConnectivityResult (older versions)
                      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);

                      if (!hasConnection) {
                        _showNoInternetDialog();
                        return;
                      }*/

                      setState(() {
                        _isLoading = true;
                      });

                      await _sendOtp(context);

                      // Only reset loading state if widget is still mounted
                      // (may be unmounted if navigation occurred on success)
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    } : null,
                    child: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Send OTP",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isButtonEnabled ? Colors.white : Colors.grey.shade500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: _isButtonEnabled ? Colors.white : Colors.grey.shade500,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 100),
                  // Security message at bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Dont worry Security",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _sendOtp(BuildContext context) async {
    final deviceId = await DeviceUtils.fetchAndSaveDeviceId();
    final url = Uri.parse(ApiEndpoints.sendOtpUrl);
    try {
      print("SEND OTP REQUEST:");
      print("URL: $url");
      print("Body: ${jsonEncode({
        'mobileNumber': _phoneNumber,
        'role': 'agent',
        'deviceId': deviceId,
      })}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': _phoneNumber,
          'role': 'agent',
          // 'existingUser': widget.existingUser,
          'deviceId': deviceId,
        }),
      );

      print('SEND OTP API Response Status: ${response.statusCode}');
      print('SEND OTP API Response Body: ${response.body}');

      String message;

      if (response.statusCode == 200) {
        message = 'OTP sent successfully';
        final data = jsonDecode(response.body);
        String otpDetails = data['otpDetails'] ?? '';
        print('SEND OTP Response Data: $data');
        // final existingUser = data['existingUser'];
        // if (existingUser) {
        //   await SharedPreferenceManager.saveString('temp_phone_number', _phoneNumber);
        //   await SharedPreferenceManager.saveRegistrationStep('verificationCode');
        //   //await SharedPreferenceManager.saveString('otpDetails', data['otpDetails'] ?? '');
        // }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationCodeScreen(
              phoneNumber: _phoneNumber, //widget.existingUser,
              otpDetails: otpDetails,
            ),
          ),
        );

        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        print('SEND OTP API Error - Status Code: ${response.statusCode}');
        try {
          final responseBody = jsonDecode(response.body);
          print('SEND OTP API Error Response: $responseBody');
          final errorCode = responseBody['code'];
          final errorMessage = responseBody['message'] ?? 'Failed to send OTP';

          if (errorCode == 'DEVICE_ID_MISMATCH') {
            _showDeviceMismatchDialog(errorMessage);
            return;
          }

          if (responseBody['message'] == "This number is already registered with another account") {
            _showSnackBar(context, responseBody['message']);
          } else {
            message = '${responseBody['message']}';
            _showSnackBar(context, message);
          }
        } catch (e) {
          print('SEND OTP API Error parsing response: $e');
          _showSnackBar(context, 'Failed to send OTP');
        }
      }
    } catch (e) {
      print('SEND OTP API Exception: $e');
      _showSnackBar(context, 'Error sending OTP: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: AppColors.gradientButton,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          padding: const EdgeInsets.all(16),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }


  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Method to show alert dialog when device mismatch occurs
  void _showDeviceMismatchDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.backgroundLightColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Device Mismatch',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
                fontSize: 20,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.headlineTextColor,
                fontSize: 15,
              ),
            ),
            actions: [
              // No button - closes the dialog
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text(
                  'No',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.unselectedColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              // Yes button - calls logout API
              TextButton(
                onPressed: () async {
                  // Navigator.of(context).pop(); // Close dialog first
                  // await _handleLogoutAndContinue();
                },
                child: Text(
                  'Yes',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.selectedColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to handle logout API call and continue with login
/*
  Future<void> _handleLogoutAndContinue() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.selectedColor),
            ),
          );
        },
      );

      // Get device ID for logout API
      final deviceId = await DeviceUtils.fetchAndSaveDeviceId();

      // Call logout API using SessionManager with mobileNumber and deviceId
      final response = await SessionManager().post(
        logout,
        body: jsonEncode({
          'mobileNumber': _phoneNumber,
          'deviceId': deviceId,
        }),
      );

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {

          await _sendOtp(context);

        } else {
          // Logout failed
          _showErrorSnackbar(data['message'] ?? 'Logout failed');
        }
      } else {
        // API call failed
        _showErrorSnackbar('Failed to logout from other device');
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      print('Error during logout: $e');
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }
*/

  // Helper method to show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: AppColors.gradientButton,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          ),
          padding: const EdgeInsets.all(16),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }

  // Method to show no internet dialog
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'No Internet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: AppColors.headlineTextColor,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Please connect to internet first to continue.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.headlineTextColor,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.selectedColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


class InfoMessageCard extends StatelessWidget {
  final String message;
  const InfoMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.headlineTextColor, // light grey background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.backgroundColor,
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}