import 'package:flutter/material.dart';
import '../constants/AppColors.dart';
import 'PhoneNumberScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildMotif() {
    return Image.asset(
      'assets/icon.png',
      width: 44,
      height: 44,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 28, left: 24, child: _buildMotif()),
            Positioned(top: 132, right: 40, child: _buildMotif()),
            Positioned(bottom: 380, left: 24, child: _buildMotif()),
            Positioned(bottom: 172, right: 40, child: _buildMotif()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/small_logo.png',
                          height: 76,
                          width: 82,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dekho',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Lexend',
                            color: Colors.black,
                            letterSpacing: -2.2,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'MAGAR PYAR SE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Lexend',
                            letterSpacing: 1.4,
                            color: AppColors.primaryColor.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'AGENT PORTAL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFA9ABB7),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Lexend',
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6, // 60% of the screen width
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhoneNumberScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Agent Login / Sign-Up \u2192',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'Lexend',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Become Agent Today',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFA2A6B1),
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Lexend',
                          ),
                        ),
                        const SizedBox(height: 44),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
