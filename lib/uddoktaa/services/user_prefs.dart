import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'dart:convert';

class UserPrefs {
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return null;
    return User.fromJson(jsonDecode(userString));
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}
