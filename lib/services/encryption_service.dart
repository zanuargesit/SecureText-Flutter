import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const String _keyPrefix = 'enc_key_';

  
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
      return 'Error: Invalid encrypted text or key';
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

  
  static Future<void> saveKey(String keyName, String key) async {
    await _storage.write(key: _keyPrefix + keyName, value: key);
  }

  static Future<String?> loadKey(String keyName) async {
    return await _storage.read(key: _keyPrefix + keyName);
  }

  static Future<List<String>> getSavedKeys() async {
    final allKeys = await _storage.readAll();
    return allKeys.keys
        .where((key) => key.startsWith(_keyPrefix))
        .map((key) => key.substring(_keyPrefix.length))
        .toList();
  }

  static Future<void> deleteKey(String keyName) async {
    await _storage.delete(key: _keyPrefix + keyName);
  }
}