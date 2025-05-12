import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Convierte la contraseña en un hash SHA256
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

