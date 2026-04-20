import 'package:dekho_agent/app_navigator_key.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

const String kMaintenanceModeMessage =
    'The app is currently under maintenance for some quick updates.';

/// True when API sent maintenance mode (bool true, or common string/int forms).
bool isApiMaintenanceMode(Map<String, dynamic> json) {
  final v = json['maintenanceMode'];
  if (v == true) return true;
  if (v is String && v.toLowerCase() == 'true') return true;
  if (v is num && v != 0) return true;
  return false;
}

/// Checks root and optional nested [data] map for maintenance flag.
bool responseIndicatesMaintenance(Map<String, dynamic> json) {
  if (isApiMaintenanceMode(json)) return true;
  final data = json['data'];
  if (data is Map<String, dynamic>) return isApiMaintenanceMode(data);
  return false;
}

/// Blocking dialog: no back, no outside tap. User must exit; cannot proceed into the app.
Future<void> showMaintenanceModeBlockingDialog(
    BuildContext? context, {
      required Future<void> Function() onRetry,
      String retrySource = 'unknown',
    }) async {
  final ctx = (context != null && context.mounted)
      ? context
      : appNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;

  return showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      final isRetrying = ValueNotifier<bool>(false);
      return PopScope(
        canPop: false,
        child: Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE85A87), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const _MaintenanceBadge(),
                  const SizedBox(height: 30),
                  const Text(
                    'MAINTENANCE\nONGOING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42 / 2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE84D72),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "We’re currently doing some\nmaintenance to improve your\nexperience",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF888A90),
                      height: 1.35,
                    ),
                  ),
                  const Spacer(flex: 5),
                  ValueListenableBuilder<bool>(
                    valueListenable: isRetrying,
                    builder: (_, retrying, __) {
                      return SizedBox(
                        width: MediaQuery.of(ctx).size.width * 0.45,
                        height: MediaQuery.of(ctx).size.height * 0.055,
                        child: ElevatedButton(
                          onPressed: retrying
                              ? null
                              : () async {
                            print(
                              'Maintenance Retry clicked from: $retrySource',
                            );
                            isRetrying.value = true;
                            try {
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              await onRetry();
                            } finally {
                              isRetrying.value = false;
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFE8E8EA),
                            disabledBackgroundColor: const Color(0xFFE1E1E4),
                            foregroundColor: const Color(0xFFFF7A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: retrying
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A1A),
                              ),
                            ),
                          )
                              : const Text(
                            'RETRY!',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 36 / 2,
                              letterSpacing: 1,
                              color: Color(0xFFFF7A1A),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _MaintenanceBadge extends StatelessWidget {
  const _MaintenanceBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(190, 190),
            painter: _DashedCirclePainter(
              color: const Color(0xFFE85A87),
              strokeWidth: 4,
              dashWidth: 8,
              dashSpace: 8,
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFB021),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3A000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Image.asset('assets/setting.png', width: 60, height: 60),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/time_filled.png',
              width: 48,
              height: 48,
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

/*
import 'package:flutter/material.dart';

const String kMaintenanceModeMessage =
    'The app is currently under maintenance for some quick updates.';

/// True when API sent maintenance mode (bool true, or common string/int forms).
bool isApiMaintenanceMode(Map<String, dynamic> json) {
  final v = json['maintenanceMode'];
  if (v == true) return true;
  if (v is String && v.toLowerCase() == 'true') return true;
  if (v is num && v != 0) return true;
  return false;
}

/// Checks root and optional nested [data] map for maintenance flag.
bool responseIndicatesMaintenance(Map<String, dynamic> json) {
  if (isApiMaintenanceMode(json)) return true;
  final data = json['data'];
  if (data is Map<String, dynamic>) return isApiMaintenanceMode(data);
  return false;
}

/// Blocking dialog: no back, no outside tap. User can only retry.
Future<void> showMaintenanceModeBlockingDialog(
  BuildContext? context, {
  Future<void> Function()? onRetry,
}) async {
  final ctx = (context != null && context.mounted)
      ? context
      : appNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;

  return showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return PopScope(
        canPop: false,
        child: Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: const Color(0xFFFF7A1A),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0x14FF7A1A),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                                'assets/maintenanceIcon.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.build_circle_outlined,
                                color: Color(0xFFFF7A1A),
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "We'll be right back!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D2538),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          kMaintenanceModeMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please try again after some time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF7A1A),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: MediaQuery.of(ctx).size.width * 0.6, // 60% of screen width
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              if (onRetry != null) {
                                await onRetry();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
        ),
      );
    },
  );
}
*/
