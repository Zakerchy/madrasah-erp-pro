import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLang {
  static const _key = 'lang_english';
  static final isEnglish = ValueNotifier<bool>(false);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnglish.value = prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnglish(bool val) async {
    isEnglish.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, val);
  }

  static String t(String bn, String en) => isEnglish.value ? en : bn;
}
