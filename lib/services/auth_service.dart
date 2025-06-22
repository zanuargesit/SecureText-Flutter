import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  static Future<bool> register(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
     
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      final user = User(username: username, password: hashedPassword);
      final userJson = jsonEncode(user.toJson());
      
      await prefs.setString(AppConstants.userKey, userJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> login(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      
      if (userJson == null) return false;
      
      final userData = jsonDecode(userJson);
      final user = User.fromJson(userData);
      
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      return user.username == username && user.password == hashedPassword;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userKey) != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }
}