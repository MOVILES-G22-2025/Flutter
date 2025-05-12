import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Retorna el hash SHA256 de una contraseña, útil para validación offline
String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}
