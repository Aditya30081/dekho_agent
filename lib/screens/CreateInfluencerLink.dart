import 'dart:convert';
import 'package:dekho_agent/constants/AppColors.dart';
import 'package:dekho_agent/screens/AgentProfileDetail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateInfluencerLink extends StatefulWidget {
  const CreateInfluencerLink({super.key});

  @override
  State<CreateInfluencerLink> createState() => _CreateInfluencerLinkState();
}

class _CreateInfluencerLinkState extends State<CreateInfluencerLink> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  bool _isProfileLoading = true;
  bool _isStatsLoading = true;
  int _selectedTabIndex = 0;
  final List<String> _tabTypes = ['overall', 'today', 'weekly', 'monthly'];
  String _selectedType = 'overall';
  Map<String, dynamic> _combinedData = {};
  List<Map<String, dynamic>> _segregatedData = [];
  
  // Profile data
  String? _userName;
  String? _userId;
  double? _rating;
  Map<String, dynamic>? _profileData;
  
  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
    _selectedType = 'overall';
    _loadSavedName();
    _loadProfile();
    _loadInfluencerLink();
    _loadAgentStats();
  }

  Future<void> _loadSavedName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('agentName');
      final savedUserId = prefs.getString('userId');
      if (savedName != null && savedName.trim().isNotEmpty) {
        setState(() {
          _userName = savedName.trim();
          _userId = savedUserId;
        });
      } else if (savedUserId != null && savedUserId.isNotEmpty) {
        setState(() {
          _userId = savedUserId;
        });
      }
    } catch (_) {}
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

            _rating = (data['rating'] ?? data['score'] ?? 0.0).toDouble();
            _profileData = data; // Store full profile data
            _isProfileLoading = false;
          });
          
          // print('GET PROFILE: Profile loaded successfully');
          // print('   Name: $_userName');
          // print('   Rating: $_rating');
          // print('   Full Profile Data: $data');
        } else {
          // print('GET PROFILE: API returned success=false');
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

  /* for testing url = https://dashboardtest.thedekhoapp.com/invite-influencer?invite=userId */
  Future<void> _loadInfluencerLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        final url = 'https://dashboard.thedekhoapp.com/invite-influencer?invite=$userId';
        setState(() {
          _userId = userId;
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

  Future<void> _loadAgentStats() async {
    try {
      setState(() {
        _isStatsLoading = true;
        _combinedData = {};
      });

      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('sessionToken');

      if (sessionToken == null || sessionToken.isEmpty) {
        setState(() {
          _isStatsLoading = false;
        });
        _showError('Session expired. Please login again.');
        return;
      }

      final selectedType = _selectedType;
      final response = await http.post(
        Uri.parse(ApiEndpoints.statsURL),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{'type': selectedType}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        // print('STATS API: Response Status: ${responseData}');

        if (responseData['success'] == true) {
          final combined =
              (responseData['combinedData'] as Map<String, dynamic>?) ?? {};
          final segregatedRaw = responseData['segregatedData'] as List<dynamic>? ?? [];
          setState(() {
            _combinedData = combined;
            _segregatedData = segregatedRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _isStatsLoading = false;
          });
        } else {
          setState(() {
            _isStatsLoading = false;
          });
          _showError('Unable to load stats');
        }
      } else {
        setState(() {
          _isStatsLoading = false;
        });
        _showError('Stats API failed (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _isStatsLoading = false;
      });
      _showError('Error loading stats: $e');
    }
  }

  Future<void> _refreshDashboardData() async {
    await Future.wait([
      _loadProfile(),
      _loadInfluencerLink(),
      _loadAgentStats(),
    ]);
  }

  String _formatNumber(num value) {
    final intValue = value.toInt();
    final str = intValue.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (match) => ',');
  }

  num _numFromCombined(String key) {
    final value = _combinedData[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
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
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: _buildDashboardAppBar(),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      /// 🔒 FIXED PART (WILL NOT SCROLL)
      Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabs(),
          const SizedBox(height: 14),
          _buildBalanceCard(),
          const SizedBox(height: 16),
        ],
      ),
    ),

            /// 🔽 SCROLLABLE PART
            Expanded(
              child: RefreshIndicator(
                color: AppColors.orange,
                onRefresh: _refreshDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOnboardCreatorsCard(),
                      const SizedBox(height: 16),
                      _buildQuickStats(),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Influencer Details'),
                      const SizedBox(height: 10),

                      if (_isStatsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_segregatedData.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No creator data available',
                              style: TextStyle(
                                color: Color(0xFF8A8D97),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_segregatedData.length, (index) {
                          final item = _segregatedData[index];
                          final name = (item['influencerName'] ?? 'Creator').toString();
                          final id = (item['influencerId'] ?? '-').toString();
                          final phone = (item['mobileNumber'] ?? '-').toString();
                          final profileImage = (item['profileImage'] ?? '-').toString();
                          final callMinutes = _formatNumber(
                            (item['totalCallMinutes'] is num)
                                ? item['totalCallMinutes'] as num
                                : num.tryParse('${item['totalCallMinutes']}') ?? 0,
                          );
                          final influencerRevenue = _formatNumber(
                            (item['influencerRevenue'] is num)
                                ? item['influencerRevenue'] as num
                                : num.tryParse('${item['influencerRevenue']}') ?? 0,
                          );
                          final commission = _formatNumber(
                            (item['influencerAgentCommission'] is num)
                                ? item['influencerAgentCommission'] as num
                                : num.tryParse('${item['influencerAgentCommission']}') ?? 0,
                          );

                          return Padding(
                            padding: EdgeInsets.only(bottom: index == _segregatedData.length - 1 ? 0 : 12),
                            child: _buildCreatorCard(
                              name: name,
                              creatorId: id,
                              phone: phone,
                              callTime: '$callMinutes Mins',
                              earned: influencerRevenue,
                              yourShare: commission,
                              isOnline: false,
                              isNew: false,
                              profileImageUrl: profileImage,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = ['Overall', 'Today', 'Weekly', 'Monthly'];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  _selectedType = _tabTypes[index];
                });
                _loadAgentStats();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.orange
                        : const Color(0xFF8D8F98),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primaryColor, AppColors.selectedColor],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/wallet.png',
                width: 24,
                height: 24,
              ),
              SizedBox(width: 8),
              const Text(
                'Total Commission',
                style: TextStyle(
                  fontSize: 21,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.diamond_rounded, color: Color(0xFFFFD457), size: 38),
              const SizedBox(width: 10),
              Text(
                _isStatsLoading
                    ? '...'
                    : _formatNumber(_numFromCombined('totalCommission')),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 62,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
      /*
          Text(
            _isStatsLoading
                ? 'Eligible Withdrawal : ...'
                : 'Eligible Withdrawal : ${_formatNumber(_numFromCombined('eligibleWithdrawal'))}',
            style: const TextStyle(
              color: Color(0xFFFBE6D8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),*/
          const SizedBox(height: 2),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _roundedActionButton(
          //         label: 'Cash Out',
          //         icon: Icons.account_balance_wallet_outlined,
          //         backgroundColor: Colors.white,
          //         textColor: const Color(0xFFDB5F1A),
          //       ),
          //     ),
          //     const SizedBox(width: 10),
          //     Expanded(
          //       child: _roundedActionButton(
          //         label: 'History',
          //         icon: Icons.history_rounded,
          //         backgroundColor: Colors.white.withValues(alpha: 0.2),
          //         textColor: Colors.white,
          //       ),
          //     ),
          //   ],
          // )
        ],
      ),
    );
  }

  Widget _roundedActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardCreatorsCard() {
    final inviteLink = _isLoading || _urlController.text.trim().isEmpty
        ? 'dekho.app/join?agt-9921'
        : _urlController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Onboard Creators',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.59,
                    child: Text(
                      inviteLink,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: _copyToClipboard,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/copy.png',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Copy Link',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Stats'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: 'assets/creators.png',
                iconColor: const Color(0xFF5B84F1),
                title: 'TOTAL\nINFLUENCERS',
                value: _isStatsLoading
                    ? '...'
                    : _formatNumber(_numFromCombined('totalCreators')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: 'assets/time.png',
                iconColor: const Color(0xFF11AF65),
                title: 'TOTAL PAID\nCALL MINS',
                value: _isStatsLoading
                    ? '...'
                    : _formatNumber(_numFromCombined('totalCallMinutesByInfluencers')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: 'assets/gifts.png',
                iconColor: const Color(0xFFE66FA5),
                title: 'TOTAL GIFTS\nRECEIVED',
                value: _isStatsLoading
                    ? '...'
                    : _formatNumber(_numFromCombined('totalGiftsRecievedByInfluencers')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2A45),
      ),
    );
  }

  Widget _buildCreatorCard({
    required String name,
    required String creatorId,
    required String phone,
    required String callTime,
    required String earned,
    required String yourShare,
    bool isOnline = false,
    bool isNew = false,
    required String profileImageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF2F2F5),
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? Text(
                        name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                        style: const TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF212A40),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isOnline)
                          _buildTag(
                            text: 'ONLINE',
                            background: const Color(0xFFE4F8EA),
                            foreground: const Color(0xFF18A14D),
                          ),
                      /*  if (isNew)
                          _buildTag(
                            text: 'NEW',
                            background: const Color(0xFFFFF5D9),
                            foreground: const Color(0xFFC38A00),
                          ),*/
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $creatorId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A8A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Image.asset('assets/call.png', width: 14, height: 14),
                          const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _horizontalDivider(),
          Row(
            children: [
              Expanded(child: _metricCell('PAID CALL MINS', callTime, false)),
              _verticalDivider(),
              Expanded(child: _metricCell('INF EARNING', earned, true)),
              _verticalDivider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _metricCell(
                      'COMMISSION',
                      '+$yourShare', true,
                      valueColor: const Color(0xFFE78824),
                      titleColor: const Color(0xFFE78824),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCell(
    String title,
    String value, bool  isIcon, {
    Color titleColor = const Color(0xFFA1A5B1),
    Color valueColor = const Color(0xFF1F2840),
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 4),
            if(isIcon)
            Icon(Icons.diamond, color: Color(0xFFFFD457), size: 18),
          ],
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 38,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE6E8EE),
    );
  }

  Widget _horizontalDivider() {
    return Container(
      height: 1,
      width: 340,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade100,
    );
  }

  Widget _buildTag({
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDashboardAppBar() {
    // print('Building Dashboard AppBar with userName: $_userName');
    return PreferredSize(
      preferredSize: const Size.fromHeight(96),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to profile screen or show profile details
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AgentProfileDetail(profileData: _profileData)),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF5D2B3), width: 2),
                    color: const Color(0xFFFFFAF5),
                  ),
                  child: Image.asset(
                    'assets/user.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName?.trim().isNotEmpty == true
                          ? _userName!.trim().toUpperCase()
                          : 'AGENT',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF252525),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                   /* Text(
                      'ID : ${(_userId != null && _userId!.isNotEmpty) ? _userId : '1234578590'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E93A3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),*/
                  ],
                ),
              ),
              GestureDetector(
                onTap: _refreshDashboardData,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6C9),
                    shape: BoxShape.circle,
                  ),
                  child:  Image.asset(
                    'assets/refresh.png',
                    width: 18,
                    height: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              icon, // Replace this with the path to your asset image
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A8A8A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B253E),
            ),
          ),
        ],
      ),
    );
  }
}

