import 'dart:convert';

import 'package:dekho_agent/config/api_endpoints.dart';
import 'package:dekho_agent/utils/DeviceUtils.dart';
import 'package:dekho_agent/utils/public_ip_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: camel_case_types
class consentDialog extends StatefulWidget {
  final String? sessionToken;

  const consentDialog({super.key, this.sessionToken});

  static Future<bool> show(BuildContext context, {String? sessionToken}) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => consentDialog(sessionToken: sessionToken),
    );
    return accepted == true;
  }

  @override
  State<consentDialog> createState() => _consentDialogState();
}

class _consentDialogState extends State<consentDialog> {
  static const String _keyAgreementAccepted = 'agreementAccepted';

  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  bool _submitting = false;
  bool _hasReachedBottom = false;
  bool _consentChecked = false;
  String _agreementContent = '';
  String? _agreementVersion;
  String? _publicIp;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAgreement();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _hasReachedBottom) return;
    final atBottom = _scrollController.position.pixels >=
        (_scrollController.position.maxScrollExtent - 16);
    if (atBottom) {
      setState(() {
        _hasReachedBottom = true;
      });
    }
  }

  Future<void> _loadAgreement() async {
    try {
      _publicIp = await PublicIpService.getPublicIp() ?? '';
      final token = await _resolveSessionToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(ApiEndpoints.agreementUrl),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _showError('Unable to load agreement');
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final html = data['agreement']?.toString() ?? '';
      _agreementVersion =
          data['policyVersion']?.toString() ?? data['agreementVersion']?.toString();

      if (html.isEmpty) {
        _showError('Agreement content is empty');
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _agreementContent = html;
        _loading = false;
      });
    } catch (e) {
      _showError('Error loading agreement: $e');
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  Future<void> _submitAgreementConsent() async {
    if (!(_hasReachedBottom && _consentChecked) || _submitting) return;

    setState(() {
      _submitting = true;
    });

    try {
      final token = await _resolveSessionToken();
      final appVersion = await DeviceUtils.getAppVersion();
      await (DeviceUtils.getSavedDeviceId() ?? DeviceUtils.fetchAndSaveDeviceId());

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final bodyMap = <String, String>{
        'IP': _publicIp ?? '',
        'accepted': 'true',
        'appVersion': appVersion,
      };

      if (_agreementVersion != null && _agreementVersion!.isNotEmpty) {
        bodyMap['policyVersion'] = _agreementVersion!;
      }
      print('Submitting agreement consent with body: $bodyMap');

      final response = await http.post(
        Uri.parse(ApiEndpoints.agreementUrl),
        headers: headers,
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Agreement consent submitted successfully'+response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyAgreementAccepted, true);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        _showError('Agreement submit failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Agreement submit error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<String?> _resolveSessionToken() async {
    if (widget.sessionToken != null && widget.sessionToken!.isNotEmpty) {
      return widget.sessionToken;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sessionToken');
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Widget _buildAgreementContent(BuildContext context) {
    final content = _agreementContent;
    final isHtml = _isHtmlContent(content);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(right: 4),
        child: isHtml ? _buildHtmlContent(content) : _buildParagraph(content),
      ),
    );
  }

  bool _isHtmlContent(String content) {
    final trimmed = content.trim();
    return trimmed.startsWith('<') ||
        (trimmed.contains('<') && trimmed.contains('>') && trimmed.contains('</'));
  }

  Widget _buildHtmlContent(String html) {
    return Html(
      data: html,
      shrinkWrap: true,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(14),
          color: Colors.grey[800],
          lineHeight: const LineHeight(1.5),
        ),
        'p': Style(
          margin: Margins.only(bottom: 8),
          fontSize: FontSize(14),
          color: Colors.grey[800],
        ),
        'h1': Style(fontSize: FontSize(18), fontWeight: FontWeight.bold),
        'h2': Style(fontSize: FontSize(16), fontWeight: FontWeight.bold),
        'h3': Style(fontSize: FontSize(15), fontWeight: FontWeight.w600),
        'ul': Style(margin: Margins.only(left: 16, bottom: 8)),
        'ol': Style(margin: Margins.only(left: 16, bottom: 8)),
        'li': Style(margin: Margins.only(bottom: 4)),
        'a': Style(
          color: Colors.blue[700],
          textDecoration: TextDecoration.underline,
        ),
      },
      onLinkTap: (url, _, __) {
        if (url != null) {
          _launchUrl(url);
        }
      },
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
        height: 1.5,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 760),
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF5EA),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/contract.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agreement',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15151C),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Please Read Carefully',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E919A),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFFAFAFB),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        child: _buildAgreementContent(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          if (!_hasReachedBottom)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Scroll to the bottom to enable consent.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E919A),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          if (_hasReachedBottom)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _consentChecked = !_consentChecked;
                                    });
                                  },
                                  child: Icon(
                                    _consentChecked
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: _consentChecked
                                        ? const Color(0xFFF8A323)
                                        : const Color(0xFFBFC3CC),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _consentChecked = !_consentChecked;
                                      });
                                    },
                                    child: const Text(
                                      'By clicking “I Agree”, you confirm that you have read, understood, and agree to be bound by the terms of this Agreement and consent to be legally bound by it.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Color(0xFF8E919A),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: (_hasReachedBottom && _consentChecked && !_submitting)
                                  ? _submitAgreementConsent
                                  : null,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Image.asset('assets/tick.png', width: 20, height: 20),
                              label: Text(
                                _submitting ? 'Submitting...' : 'I Agree',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                disabledBackgroundColor: const Color(0xFFDADDE4),
                                backgroundColor: const Color(0xFFF76F1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}
