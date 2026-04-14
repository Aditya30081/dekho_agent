import 'dart:io';

import 'package:apk_sideload/install_apk.dart';
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

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDownloading = false;

        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF4E6),
                        border: Border.all(color: const Color(0xFFF8E8D0)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.settings,
                          size: 40,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "We'll be back!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E1633),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 10),
                    // const Text(
                    //   'Girls are waiting for you! 😍',
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w700,
                    //     color: Color(0xFFE57B0F),
                    //     fontFamily: 'Inter',
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    const Text(
                      'Please update the app to continue connecting and video calling without interruptions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF5E6678),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE98709), Color(0xFFE14C45)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton.icon(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: isDownloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 22),
                          label: Text(
                            isDownloading ? 'Downloading...' : 'Update Now',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
