import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  // Create a key and iv for AES encryption (in production, these should be securely stored)
  static final _key = encrypt.Key.fromLength(32); // 256-bit key
  static final _iv = encrypt.IV.fromLength(16);   // 128-bit IV
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  
  // Encrypt a string using bcrypt (one-way hash, for passwords)
  static String hashWithBcrypt(String text) {
    return BCrypt.hashpw(text, BCrypt.gensalt());
  }
  
  // Verify a string against a bcrypt hash
  static bool verifyBcrypt(String text, String hashedText) {
    return BCrypt.checkpw(text, hashedText);
  }
  
  // Encrypt a string
  static String encryptString(String text) {
    final encrypted = _encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }
  
  // Decrypt a string
  static String decryptString(String encryptedText) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Error decrypting string: $e');
      return 'Decryption error';
    }
  }
  
  // Encrypt a map of user details
  static Map<String, dynamic> encryptUserDetails(Map<String, dynamic> userDetails) {
    final Map<String, dynamic> encryptedDetails = {};
    
    userDetails.forEach((key, value) {
      if (value != null) {
        if (value is String) {
          encryptedDetails[key] = encryptString(value);
        } else if (value is bool || value is num) {
          encryptedDetails[key] = encryptString(value.toString());
        } else if (value is Map) {
          encryptedDetails[key] = encryptString(jsonEncode(value));
        } else if (value is List) {
          encryptedDetails[key] = encryptString(jsonEncode(value));
        } else {
          encryptedDetails[key] = encryptString(value.toString());
        }
      }
    });
    
    return encryptedDetails;
  }
  
  // Decrypt a map of user details
  static Map<String, dynamic> decryptUserDetails(Map<String, dynamic> encryptedDetails) {
    final Map<String, dynamic> decryptedDetails = {};
    
    try {
      encryptedDetails.forEach((key, value) {
        if (value != null && value is String) {
          final decrypted = decryptString(value);
          
          // Try to parse as JSON if possible
          try {
            decryptedDetails[key] = jsonDecode(decrypted);
          } catch (_) {
            // If not JSON, try to parse as numbers or booleans
            if (decrypted == 'true') {
              decryptedDetails[key] = true;
            } else if (decrypted == 'false') {
              decryptedDetails[key] = false;
            } else if (int.tryParse(decrypted) != null) {
              decryptedDetails[key] = int.parse(decrypted);
            } else if (double.tryParse(decrypted) != null) {
              decryptedDetails[key] = double.parse(decrypted);
            } else {
              decryptedDetails[key] = decrypted;
            }
          }
        }
      });
    } catch (e) {
      print('Error decrypting user details: $e');
    }
    
    return decryptedDetails;
  }
  
  // Generate SHA-256 hash of a string
  static String generateSHA256(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
} 