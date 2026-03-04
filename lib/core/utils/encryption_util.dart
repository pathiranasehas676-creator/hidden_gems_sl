import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'secure_logger.dart';

class EncryptionUtil {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'tripme_aes_key';

  static Future<Key> _getOrCreateKey() async {
    String? storedKey = await _storage.read(key: _keyAlias);
    if (storedKey == null) {
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _keyAlias, value: key.base64);
      return key;
    }
    return Key.fromBase64(storedKey);
  }

  static Future<String> encrypt(String plainText) async {
    try {
      final key = await _getOrCreateKey();
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Format: IV(base64):Cipher(base64)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      SecureLogger.error("Encryption Failure. Operating in fallback.", e);
      return plainText; // Fallback
    }
  }

  static Future<String> decrypt(String cipherPayload) async {
    try {
      if (!cipherPayload.contains(':')) return cipherPayload; // Fallback for unencrypted old data

      final parts = cipherPayload.split(':');
      final iv = IV.fromBase64(parts[0]);
      final cipherText = parts[1];
      
      final key = await _getOrCreateKey();
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt64(cipherText, iv: iv);
      return decrypted;
    } catch (e) {
      SecureLogger.error("Decryption Failure. Purging data.", e);
      return '{}';
    }
  }
}
