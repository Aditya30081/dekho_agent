import 'dart:io';
import 'dart:math' as math;

import 'package:apk_sideload/install_apk.dart';
import 'package:dekho_agent/constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';

class ForceUpdateHelper {
  static bool _isDialogVisible = false;

  static bool maybeShowForceUpdateDialog(
    BuildContext context,
    dynamic responseBody,
  ) {
    if (responseBody is! Map<String, dynamic>) {
      return false;
    }

    if (responseBody['latestVersion'] != false) {
      return false;
    }

    _showForceUpdateDialog(context);
    return true;
  }

  static void _showForceUpdateDialog(BuildContext context) {
    if (_isDialogVisible || !context.mounted) {
      return;
    }

    _isDialogVisible = true;
    final luckyNumber = '${math.Random().nextInt(99) + 1}';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDownloading = false;

        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE64A8A), width: 2),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 14,
                        top: 250,
                        child: Image.asset(
                          'assets/fire.png',
                          width: 54,
                          height: 54,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.local_fire_department, color: Color(0xFFFF7B18), size: 44),
                        ),
                      ),
                      Positioned(
                        right: 22,
                        top: 210,
                        child: Image.asset(
                          'assets/star.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.auto_awesome, color: AppColors.primaryColor, size: 40),
                        ),
                      ),
                      Positioned(
                        right: 64,
                        top: 420,
                        child: Image.asset(
                          'assets/fire.png',
                          width: 54,
                          height: 54,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.local_fire_department, color: Color(0xFFFF7B18), size: 44),
                        ),
                      ),
                      Positioned(
                        left: 52,
                        bottom: 160,
                        child: Image.asset(
                          'assets/fire.png',
                          width: 54,
                          height: 54,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.local_fire_department, color: Color(0xFFFF7B18), size: 44),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/image.png',
                                      width: double.infinity,
                                      height: MediaQuery.of(context).size.height * 0.25,
                                      fit: BoxFit.contain,
                                    ),
                                    // const SizedBox(height: 24),
                                    // _DashedNumberCircle(number: luckyNumber),
                                    // const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: MediaQuery.of(context).size.height * 0.3, // Adjust the multiplier as needed
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            children: [
                                              TextSpan(text: 'We’ve improved your\nexperience! '),
                                              TextSpan(
                                                text: 'Update Now',
                                                style: TextStyle(
                                                  color: Color(0xFFF76F1A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'New version is available now!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.height * 0.06,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(36),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF7B18), Color(0xFFFF3D3B)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40FF6A00),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: TextButton.icon(
                                  onPressed: isDownloading
                                      ? null
                                      : () async {
                                          setDialogState(() {
                                            isDownloading = true;
                                          });

                                          await _downloadAndInstallApk(dialogContext);

                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              isDownloading = false;
                                            });
                                          }
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(36),
                                    ),
                                  ),
                                  icon: isDownloading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Image.asset('assets/download.png', width: 20, height: 20, color: Colors.white, errorBuilder: (_, __, ___) => const Icon(Icons.download_rounded, size: 20, color: Colors.white)),
                                  label: Text(
                                    isDownloading ? 'DOWNLOADING...' : 'UPDATE NOW!',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                      fontWeight: FontWeight.w700,
                                    ),
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
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _isDialogVisible = false;
    });
  }

  static Future<void> _downloadAndInstallApk(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.apkDownloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download APK (${response.statusCode})');
      }

      final Directory dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}${Platform.pathSeparator}${ApiConfig.apkFileName}';
      final apkFile = File(filePath);

      await apkFile.writeAsBytes(response.bodyBytes, flush: true);
      await InstallApk().installApk(apkFile.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _DashedNumberCircle extends StatelessWidget {
  final String number;

  const _DashedNumberCircle({required this.number});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(196, 196),
            painter: _DashedCirclePainter(
              color: const Color(0xFFF05572),
              strokeWidth: 5,
              dashWidth: 8,
              dashSpace: 12,
            ),
          ),
          Text(
            number,
            style: const TextStyle(
              fontSize: 78,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Color(0xFFFF7A18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final radius = (size.width / 2) - strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final sweep = (2 * math.pi) / dashCount;
    final dashSweep = sweep * (dashWidth / (dashWidth + dashSpace));

    for (int i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
