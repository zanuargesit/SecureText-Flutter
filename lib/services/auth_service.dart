import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();


  static Future<bool> register(String username, String password) async {
    try {

      final existingUser = await getUserByUsername(username);
      if (existingUser != null) {
        return false; 
      }


      final hashedPassword = _hashPassword(password);


      final newUser = User(username: username, password: hashedPassword);


      final users = await getAllUsers();
      users.add(newUser);


      await _saveUsersList(users);

      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }


  static Future<bool> login(String username, String password) async {
    try {
      final user = await getUserByUsername(username);
      if (user == null) {
        return false;
      }

      final hashedPassword = _hashPassword(password);
      if (user.password == hashedPassword) {

        await _storage.write(key: AppConstants.currentUserKey, value: username);
        return true;
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }


  static Future<void> logout() async {
    try {
      await _storage.delete(key: AppConstants.currentUserKey);
    } catch (e) {
      print('Logout error: $e');
    }
  }


  static Future<String?> getCurrentUser() async {
    try {
      return await _storage.read(key: AppConstants.currentUserKey);
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }


  static Future<bool> isLoggedIn() async {
    final currentUser = await getCurrentUser();
    return currentUser != null;
  }


  static Future<User?> getUserByUsername(String username) async {
    try {
      final users = await getAllUsers();
      for (User user in users) {
        if (user.username == username) {
          return user;
        }
      }
      return null;
    } catch (e) {
      print('Get user by username error: $e');
      return null;
    }
  }


  static Future<List<User>> getAllUsers() async {
    try {
      final usersJson = await _storage.read(key: AppConstants.usersListKey);
      if (usersJson != null) {
        final List<dynamic> usersList = jsonDecode(usersJson);
        return usersList.map((userJson) => User.fromJson(userJson)).toList();
      }
      return [];
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }


  static Future<bool> deleteUser(String username, String password) async {
    try {
      final user = await getUserByUsername(username);
      if (user == null) {
        return false;
      }

      final hashedPassword = _hashPassword(password);
      if (user.password != hashedPassword) {
        return false;
      }


      final users = await getAllUsers();
      users.removeWhere((u) => u.username == username);
      await _saveUsersList(users);


      await _deleteUserData(username);


      final currentUser = await getCurrentUser();
      if (currentUser == username) {
        await logout();
      }

      return true;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }


  static Future<bool> changePassword(String username, String oldPassword, String newPassword) async {
    try {
      final user = await getUserByUsername(username);
      if (user == null) {
        return false;
      }

      final hashedOldPassword = _hashPassword(oldPassword);
      if (user.password != hashedOldPassword) {
        return false;
      }


      final hashedNewPassword = _hashPassword(newPassword);
      final users = await getAllUsers();

      for (int i = 0; i < users.length; i++) {
        if (users[i].username == username) {
          users[i] = User(username: username, password: hashedNewPassword);
          break;
        }
      }

      await _saveUsersList(users);
      return true;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }


  static Future<bool> usernameExists(String username) async {
    final user = await getUserByUsername(username);
    return user != null;
  }


  static Future<int> getUserCount() async {
    final users = await getAllUsers();
    return users.length;
  }


  static String _hashPassword(String password) {

    return password.hashCode.toString();
  }

  static Future<void> _saveUsersList(List<User> users) async {
    final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
    await _storage.write(key: AppConstants.usersListKey, value: usersJson);
  }

  static Future<void> _deleteUserData(String username) async {
    try {

      final allKeys = await _storage.readAll();
      final keysToDelete = <String>[];


      for (String key in allKeys.keys) {
        if (key.contains('_$username') || key.endsWith('_$username')) {
          keysToDelete.add(key);
        }
      }


      for (String key in keysToDelete) {
        await _storage.delete(key: key);
      }
    } catch (e) {
      print('Failed to delete user data: $e');
    }
  }


  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('Clear all data error: $e');
    }
  }
}
