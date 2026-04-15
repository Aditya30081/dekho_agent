import 'package:dekho_agent/app_navigator_key.dart';
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
