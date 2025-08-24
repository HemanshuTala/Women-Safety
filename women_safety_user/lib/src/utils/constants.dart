// Example: constants.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

const kPrimaryColor = Color(0xFFE91E63);  // Pink color
const kWhiteColor = Colors.white;
const kTextColor = Color(0xFF333333);
const kErrorColor = Colors.redAccent;

final kPoppinsTextTheme = TextTheme(
  displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 28, color: kTextColor),
  titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 20, color: kTextColor),
  bodyLarge: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: kTextColor),
  bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: kTextColor.withOpacity(0.7)),
);

// src/utils/constants.dart
const String backendUrl = "https://women-safety-mcsp.onrender.com";
const String socketUrl = "https://women-safety-mcsp.onrender.com";
const String _openRouteApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjYwZGFkNTMwNzc3YzRmNTlhMDU4YmI2MjI3MTk5Yzk2IiwiaCI6Im11cm11cjY0In0=';

Future<String> getUserToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_token') ?? '';
}
Future<String> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_id') ?? '';
}
