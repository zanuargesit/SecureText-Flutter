import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const String _keyPrefix = 'enc_key_';
  static const String _encryptionHistoryPrefix = 'encryption_history_';
  static const String _decryptionHistoryPrefix = 'decryption_history_';
  static const String _currentUserKey = 'current_user';


  static String caesarEncrypt(String text, int shift) {
    String result = '';
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {

        result += String.fromCharCode((char.codeUnitAt(0) - 65 + shift) % 26 + 65);
      } else if (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122) {

        result += String.fromCharCode((char.codeUnitAt(0) - 97 + shift) % 26 + 97);
      } else {
        result += char;
      }
    }
    return result;
  }

  static String caesarDecrypt(String text, int shift) {
    return caesarEncrypt(text, 26 - (shift % 26));
  }

  static String base64Encrypt(String text, String key) {
    final keyBytes = utf8.encode(key);
    final textBytes = utf8.encode(text);
    final encrypted = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  static String base64Decrypt(String encryptedText, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final encryptedBytes = base64.decode(encryptedText);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Invalid encrypted text or key');
    }
  }

  static String generateRandomKey({int length = 16}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static int generateRandomNumber({int min = 1, int max = 25}) {
    final random = Random.secure();
    return min + random.nextInt(max - min + 1);
  }

  static Future<String?> getCurrentUser() async {
    return await _storage.read(key: _currentUserKey);
  }

  static Future<void> saveKey(String keyName, String key) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      await _storage.write(key: '${_keyPrefix}${currentUser}_$keyName', value: key);
    }
  }

  static Future<String?> loadKey(String keyName) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      return await _storage.read(key: '${_keyPrefix}${currentUser}_$keyName');
    }
    return null;
  }

  static Future<List<String>> getSavedKeys() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return [];

    final allKeys = await _storage.readAll();
    final userKeyPrefix = '${_keyPrefix}${currentUser}_';

    return allKeys.keys
        .where((key) => key.startsWith(userKeyPrefix))
        .map((key) => key.substring(userKeyPrefix.length))
        .toList();
  }

  static Future<void> deleteKey(String keyName) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      await _storage.delete(key: '${_keyPrefix}${currentUser}_$keyName');
    }
  }

  static Future<void> saveToEncryptionHistory({
    required String originalText,
    required String encryptedText,
    required String key,
    required String method,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final historyKey = '$_encryptionHistoryPrefix$currentUser';
      final historyJson = await _storage.read(key: historyKey);
      List<Map<String, dynamic>> history = [];

      if (historyJson != null) {
        final List<dynamic> decodedHistory = jsonDecode(historyJson);
        history = decodedHistory.cast<Map<String, dynamic>>();
      }

      final newEntry = {
        'originalText': originalText,
        'encryptedText': encryptedText,
        'key': key,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      };

      history.insert(0, newEntry);

      if (history.length > 100) {
        history = history.take(100).toList();
      }

      await _storage.write(key: historyKey, value: jsonEncode(history));
    } catch (e) {
      print('Failed to save encryption history: $e');
    }
  }

  static Future<void> saveToDecryptionHistory({
    required String originalText,
    required String decryptedText,
    required String key,
    required String method,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final historyKey = '$_decryptionHistoryPrefix$currentUser';
      final historyJson = await _storage.read(key: historyKey);
      List<Map<String, dynamic>> history = [];

      if (historyJson != null) {
        final List<dynamic> decodedHistory = jsonDecode(historyJson);
        history = decodedHistory.cast<Map<String, dynamic>>();
      }

      final newEntry = {
        'originalText': originalText,
        'decryptedText': decryptedText,
        'key': key,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      };

      history.insert(0, newEntry);

      if (history.length > 100) {
        history = history.take(100).toList();
      }

      await _storage.write(key: historyKey, value: jsonEncode(history));
    } catch (e) {
      print('Failed to save decryption history: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getEncryptionHistory() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return [];

      final historyKey = '$_encryptionHistoryPrefix$currentUser';
      final historyJson = await _storage.read(key: historyKey);
      if (historyJson != null) {
        final List<dynamic> decodedHistory = jsonDecode(historyJson);
        return decodedHistory.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Failed to load encryption history: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDecryptionHistory() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return [];

      final historyKey = '$_decryptionHistoryPrefix$currentUser';
      final historyJson = await _storage.read(key: historyKey);
      if (historyJson != null) {
        final List<dynamic> decodedHistory = jsonDecode(historyJson);
        return decodedHistory.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Failed to load decryption history: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllHistory() async {
    try {
      final encryptionHistory = await getEncryptionHistory();
      final decryptionHistory = await getDecryptionHistory();

      final allHistory = <Map<String, dynamic>>[];

      for (var item in encryptionHistory) {
        allHistory.add({
          ...item,
          'isEncryption': true,
        });
      }

      for (var item in decryptionHistory) {
        allHistory.add({
          ...item,
          'isEncryption': false,
        });
      }

      allHistory.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });

      return allHistory;
    } catch (e) {
      print('Failed to load all history: $e');
      return [];
    }
  }

  static Future<void> deleteEncryptionHistoryItem(int index) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final historyKey = '$_encryptionHistoryPrefix$currentUser';
      final historyJson = await _storage.read(key: historyKey);
      if (historyJson != null) {
        final List<dynamic> decodedHistory = jsonDecode(historyJson);
        List<Map<String, dynamic>> history = decodedHistory.cast<Map<String, dynamic>>();

        if (index >= 0 && index < history.length) {
          history.removeAt(index);
          await _storage.write(key: historyKey, value: jsonEncode(history));
        }
      }
    } catch (e) {
      throw Exception('Failed to delete encryption history item: $e');
    }
  }

  static Future<void> deleteDecryptionHistoryItem(int index) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final historyKey = '$_decryptionHistoryPrefix$currentUser';
      final historyJson = await _storage.read(key: historyKey);
      if (historyJson != null) {
        final List<dynamic> decodedHistory = jsonDecode(historyJson);
        List<Map<String, dynamic>> history = decodedHistory.cast<Map<String, dynamic>>();

        if (index >= 0 && index < history.length) {
          history.removeAt(index);
          await _storage.write(key: historyKey, value: jsonEncode(history));
        }
      }
    } catch (e) {
      throw Exception('Failed to delete decryption history item: $e');
    }
  }

  static Future<void> clearEncryptionHistory() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final historyKey = '$_encryptionHistoryPrefix$currentUser';
      await _storage.delete(key: historyKey);
    } catch (e) {
      throw Exception('Failed to clear encryption history: $e');
    }
  }

  static Future<void> clearDecryptionHistory() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final historyKey = '$_decryptionHistoryPrefix$currentUser';
      await _storage.delete(key: historyKey);
    } catch (e) {
      throw Exception('Failed to clear decryption history: $e');
    }
  }

  static Future<void> clearAllHistory() async {
    try {
      await clearEncryptionHistory();
      await clearDecryptionHistory();
    } catch (e) {
      throw Exception('Failed to clear all history: $e');
    }
  }

  static Future<void> deleteAllUserData(String username) async {
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

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool validateCaesarKey(String key) {
    try {
      final shift = int.parse(key);
      return shift >= 1 && shift <= 25;
    } catch (e) {
      return false;
    }
  }

  static bool validateBase64Key(String key) {
    return key.isNotEmpty && key.length >= 1;
  }

  @deprecated
  static Future<void> saveToHistory({
    required String originalText,
    required String encryptedText,
    required String key,
    required String method,
    required bool isEncryption,
  }) async {
    if (isEncryption) {
      await saveToEncryptionHistory(
        originalText: originalText,
        encryptedText: encryptedText,
        key: key,
        method: method,
      );
    } else {
      await saveToDecryptionHistory(
        originalText: originalText,
        decryptedText: encryptedText,
        key: key,
        method: method,
      );
    }
  }

  @deprecated
  static Future<List<Map<String, dynamic>>> getHistory() async {
    return await getAllHistory();
  }

  @deprecated
  static Future<void> deleteHistoryItem(int index) async {
    throw Exception('Use deleteEncryptionHistoryItem or deleteDecryptionHistoryItem instead');
  }

  @deprecated
  static Future<void> clearHistory() async {
    await clearAllHistory();
  }
}
