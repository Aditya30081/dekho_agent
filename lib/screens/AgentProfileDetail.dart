import 'dart:convert';
import 'package:dekho_agent/screens/CreateInfluencerLink.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/AppColors.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/api_endpoints.dart';

class AgentProfileDetail extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  
  const AgentProfileDetail({super.key, this.profileData});

  @override
  State<AgentProfileDetail> createState() => _AgentProfileDetailState();
}

class _AgentProfileDetailState extends State<AgentProfileDetail> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Bank details controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankBranchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateFormFromProfileData();
  }

  void _populateFormFromProfileData() {
    if (widget.profileData == null) {
      return;
    }

    final data = widget.profileData!;
    
    // Populate name
    if (data['name'] != null) {
      _nameController.text = data['name'].toString();
    }
    
    // Populate email
    if (data['email'] != null) {
      _emailController.text = data['email'].toString();
    }
    
    // Populate bank details
    if (data['bankDetails'] != null && data['bankDetails'] is List) {
      final bankDetails = data['bankDetails'] as List;
      if (bankDetails.isNotEmpty) {
        final bankDetail = bankDetails[0] as Map<String, dynamic>;
        
        if (bankDetail['name'] != null) {
          _bankNameController.text = bankDetail['name'].toString();
        }
        if (bankDetail['pan'] != null) {
          _panController.text = bankDetail['pan'].toString();
        }
        if (bankDetail['aadharNumber'] != null) {
          _aadharController.text = bankDetail['aadharNumber'].toString();
        }
        if (bankDetail['bankAccountNumber'] != null) {
          _accountNumberController.text = bankDetail['bankAccountNumber'].toString();
        }
        if (bankDetail['ifsc'] != null) {
          _ifscController.text = bankDetail['ifsc'].toString();
        }
        if (bankDetail['bankBranchName'] != null) {
          _bankBranchController.text = bankDetail['bankBranchName'].toString();
        }
      }
    }
    
    print('PROFILE DATA: Form populated with profile data');
    print('   Name: ${_nameController.text}');
    print('   Email: ${_emailController.text}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankBranchController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('sessionToken');

      if (sessionToken == null || sessionToken.isEmpty) {
        _showError('Session token not found. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare bank details
      final bankDetails = [
        {
          "name": _bankNameController.text.trim(),
          "pan": _panController.text.trim(),
          "aadharNumber": _aadharController.text.trim(),
          "bankAccountNumber": _accountNumberController.text.trim(),
          "ifsc": _ifscController.text.trim(),
          "bankBranchName": _bankBranchController.text.trim(),
          "isPrimary": true
        }
      ];

      // Get mobile number from SharedPreferences
      // The mobile number should be saved during login/OTP verification
      String? mobileNumber = prefs.getString('mobileNumber') ?? 
                            prefs.getString('mobile_number');

      // Prepare request body
      final requestBody = <String, dynamic>{
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "bankDetails": bankDetails,
        "profileCompleted": true
      };
      
      // Add mobile number if available
      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        requestBody["mobileNumber"] = mobileNumber;
      }

      print("UPDATE PROFILE REQUEST:");
      print("URL: ${ApiEndpoints.updateProfileUrl}");
      print("REQUEST BODY:");
      print(const JsonEncoder.withIndent('  ').convert(requestBody));

      final response = await http.post(
        Uri.parse(ApiEndpoints.updateProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
        body: jsonEncode(requestBody),
      );

      print('UPDATE PROFILE API Response Status: ${response.statusCode}');
      print('UPDATE PROFILE API Response Body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('UPDATE PROFILE Response Data: $responseData');
        if (responseData['success'] == true || response.statusCode == 200) {
          _showSuccess('Profile updated successfully!');
          // Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInfluencerLink()));
        } else {
          _showError(responseData['message'] ?? 'Failed to update profile');
        }
      } else {
        print('UPDATE PROFILE API Error - Status Code: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('UPDATE PROFILE API Error Response: $errorData');
          final errorMessage = errorData['message'] ?? 
                              errorData['error'] ?? 
                              'Failed to update profile';
          _showError(errorMessage.toString());
        } catch (e) {
          print('UPDATE PROFILE API Error parsing response: $e');
          _showError('Failed to update profile. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('UPDATE PROFILE API Exception: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('An error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Agent Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Name Field
                    _buildLabel('Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Enter your name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Bank Details Section
                    const Text(
                      'Bank Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bank Name
                    _buildLabel('Account Holder Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _bankNameController,
                      hintText: 'Enter account holder name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Account holder name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // PAN
                    _buildLabel('PAN Number'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _panController,
                      hintText: 'Enter PAN number',
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'PAN number is required';
                        }
                        if (value.trim().length != 10) {
                          return 'PAN must be 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Aadhar Number
                    _buildLabel('Aadhar Number'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _aadharController,
                      hintText: 'Enter Aadhar number',
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Aadhar number is required';
                        }
                        if (value.trim().length != 12) {
                          return 'Aadhar must be 12 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bank Account Number
                    _buildLabel('Bank Account Number'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _accountNumberController,
                      hintText: 'Enter bank account number',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bank account number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // IFSC Code
                    _buildLabel('IFSC Code'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _ifscController,
                      hintText: 'Enter IFSC code',
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'IFSC code is required';
                        }
                        if (value.trim().length != 11) {
                          return 'IFSC must be 11 characters';
                        }
                        if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.trim())) {
                          return 'Invalid IFSC code format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bank Branch Name
                    _buildLabel('Bank Branch Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _bankBranchController,
                      hintText: 'Enter bank branch name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bank branch name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: '',
      ),
    );
  }
}
