import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/AppColors.dart';
import '../config/api_endpoints.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'AgentProfileDetail.dart';

class CreateInfluencerLink extends StatefulWidget {
  const CreateInfluencerLink({super.key});

  @override
  State<CreateInfluencerLink> createState() => _CreateInfluencerLinkState();
}

class _CreateInfluencerLinkState extends State<CreateInfluencerLink> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  bool _isProfileLoading = true;
  
  // Profile data
  String? _userName;
  String? _profileImageUrl;
  double? _rating;
  Map<String, dynamic>? _profileData;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadInfluencerLink();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('sessionToken');

      if (sessionToken == null || sessionToken.isEmpty) {
        print('GET PROFILE: No session token found');
        setState(() {
          _isProfileLoading = false;
        });
        return;
      }

      print('GET PROFILE: Fetching profile data...' +ApiEndpoints.getProfileUrl);
      final response = await http.get(
        Uri.parse(ApiEndpoints.getProfileUrl),
        headers: {
          'Authorization': 'Bearer $sessionToken',
        },
        /*body: jsonEncode(<String, dynamic>{}),*/
      );

      print('GET PROFILE: Response Status: ${response.statusCode}');
      print('GET PROFILE: Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true || response.statusCode == 200) {
          final data = responseData['data'] ?? responseData;
          
          setState(() {
            _userName = data['name'] ?? data['userName'] ?? 'User';
            _profileImageUrl = data['profileImage'] ?? data['profilePicture'] ?? data['image'];
            _rating = (data['rating'] ?? data['score'] ?? 0.0).toDouble();
            _profileData = data; // Store full profile data
            _isProfileLoading = false;
          });
          
          print('GET PROFILE: Profile loaded successfully');
          print('   Name: $_userName');
          print('   Rating: $_rating');
          print('   Full Profile Data: $data');
        } else {
          print('GET PROFILE: API returned success=false');
          setState(() {
            _isProfileLoading = false;
          });
        }
      } else {
        print('GET PROFILE: Failed with status ${response.statusCode}');
        setState(() {
          _isProfileLoading = false;
        });
      }
    } catch (e) {
      print('GET PROFILE: Error: $e');
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _loadInfluencerLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        final url = 'https://dashboard.thedekhoapp.com/invite-influencer?invite=$userId';
        setState(() {
          _urlController.text = url;
          _isLoading = false;
        });
      } else {
        setState(() {
          _urlController.text = 'https://dashboard.thedekhoapp.com/invite-influencer?invite=agentid';
          _isLoading = false;
        });
        _showError('User ID not found. Please login again.');
      }
    } catch (e) {
      setState(() {
        _urlController.text = 'https://dashboard.thedekhoapp.com/invite-influencer?invite=agentid';
        _isLoading = false;
      });
      _showError('Error loading user ID: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('No URL to copy');
      return;
    }

    Clipboard.setData(ClipboardData(text: url));
    _showSuccess('URL copied to clipboard!');
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
      appBar: _buildProfileAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL Label
            _buildLabel('Influencer Link URL'),
            const SizedBox(height: 8),
            
            // URL TextField with Copy Button
            Row(
              children: [
                Expanded(
                  child: _isLoading
                      ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _buildTextField(
                          controller: _urlController,
                          hintText: 'Enter influencer link URL',
                          enabled: true,
                        ),
                ),
                const SizedBox(width: 12),
                // Copy Button
                Container(
                  height: 56, // Match text field height
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _copyToClipboard,
                      borderRadius: BorderRadius.circular(8),
                      child: const Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
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
      keyboardType: keyboardType ?? TextInputType.url,
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

  PreferredSizeWidget _buildProfileAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  // Profile Picture
                 ClipOval(
                    child: Image.asset(
                      'assets/placeholder.png', // Placeholder image
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Greeting and Name with Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hello, ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            Text(
                              _userName ?? 'User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            /*if (_rating != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '($_rating⭐)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            ],*/
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Edit Profile
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AgentProfileDetail(profileData: _profileData),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu Icon
                  /*IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {
                      // TODO: Implement menu functionality
                    },
                  ),*/
                ],
              ),
              const SizedBox(height: 8),
              // Separator line
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

