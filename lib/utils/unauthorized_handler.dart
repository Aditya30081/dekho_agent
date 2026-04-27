import 'package:dekho_agent/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedHandler {
  static Future<bool> handle401(BuildContext context, int statusCode) async {
    if (statusCode != 401) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionToken');

    Fluttertoast.showToast(
      msg: 'You have been logged out',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    if (!context.mounted) return true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return true;
  }
}
