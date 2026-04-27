import 'package:flutter/material.dart';

class LoggedOutScreen extends StatelessWidget {
  const LoggedOutScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F2EC),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: Color(0xFFF5791B),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Logged Out',
                  style: TextStyle(
                    color: Color(0xFFF27016),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your device has been safely logged\nout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7F8591),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 62,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4CF9F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
