import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/AppColors.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateInfluencerLink extends StatefulWidget {
  const CreateInfluencerLink({super.key});

  @override
  State<CreateInfluencerLink> createState() => _CreateInfluencerLinkState();
}

class _CreateInfluencerLinkState extends State<CreateInfluencerLink> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInfluencerLink();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Create Influencer Link',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
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
}

