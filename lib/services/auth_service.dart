// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
//  CONFIGURAÇÃO EMAILJS
//  1. Crie conta gratuita em https://www.emailjs.com
//  2. Crie um Email Service (Gmail, Outlook, etc.)
//  3. Crie um Email Template com as variáveis abaixo:
//       {{to_email}}  {{to_name}}  {{reset_code}}
//  4. Copie os IDs e cole aqui:
// ─────────────────────────────────────────────────────────────
class EmailJSConfig {
  static const serviceId = 'service_o0o9oll'; // ex: service_abc123
  static const templateId = 'template_ypdauyj'; // ex: template_xyz789
  static const publicKey = 'xL_XIQURKxegwBAhe'; // ex: aBcDeFgH1234567
}
// ─────────────────────────────────────────────────────────────

class AuthService extends ChangeNotifier {
  static const _keyHash = 'auth_password_hash';
  static const _keyEmail = 'auth_recovery_email';
  static const _keyUserName = 'auth_user_name';
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyResetCode = 'auth_reset_code';
  static const _keyResetExpiry = 'auth_reset_expiry';

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthService() {
    _checkSession();
  }

  String _hash(String input) {
    final bytes = utf8.encode(input + 'stockpro_salt_2024');
    return sha256.convert(bytes).toString();
  }

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    notifyListeners();
  }

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyHash);
  }

  Future<void> setupPassword(String password, String email,
      {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHash, _hash(password));
    await prefs.setString(_keyEmail, email);
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_keyUserName, name);
    }
  }

  Future<bool> login(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyHash) ?? '';
    if (stored.isNotEmpty && _hash(password) == stored) {
      _isLoggedIn = true;
      await prefs.setBool(_keyLoggedIn, true);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    notifyListeners();
  }

  Future<String?> getRecoveryEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<bool> updatePassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHash, _hash(newPassword));
    return true;
  }

  Future<bool> sendRecoveryEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail) ?? '';
    final name = prefs.getString(_keyUserName) ?? 'Usuário';

    if (email.isEmpty) return false;

    final code = _generateCode();
    final expiry =
        DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch;

    await prefs.setString(_keyResetCode, _hash(code));
    await prefs.setInt(_keyResetExpiry, expiry);

    try {
      await _sendViaEmailJS(
        toEmail: email,
        toName: name,
        resetCode: code,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EmailJS fail: $e');
      }
      return false;
    }
  }

  Future<void> _sendViaEmailJS({
    required String toEmail,
    required String toName,
    required String resetCode,
  }) async {
    const url = 'https://api.emailjs.com/api/v1.0/email/send';

    final payload = jsonEncode({
      'service_id': EmailJSConfig.serviceId,
      'template_id': EmailJSConfig.templateId,
      'user_id': EmailJSConfig.publicKey,
      'template_params': {
        'to_email': toEmail,
        'to_name': toName,
        'reset_code': resetCode,
      },
    });

    final response = await http
        .post(Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'origin': 'http://localhost',
            },
            body: payload)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw EmailSendException(
        'EmailJS retornou status ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<bool> verifyResetCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_keyResetCode);
    final expiry = prefs.getInt(_keyResetExpiry) ?? 0;

    if (storedHash == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > expiry) return false;
    return storedHash == _hash(code);
  }

  Future<bool> resetPassword(String code, String newPassword) async {
    final valid = await verifyResetCode(code);
    if (!valid) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHash, _hash(newPassword));
    await prefs.remove(_keyResetCode);
    await prefs.remove(_keyResetExpiry);
    return true;
  }
}

class EmailSendException implements Exception {
  final String message;
  const EmailSendException(this.message);

  @override
  String toString() => 'EmailSendException: $message';
}
