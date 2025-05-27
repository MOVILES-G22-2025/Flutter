import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../data/local/models/otp_info.dart';

class OtpService {
  static Future<void> generateAndSendOtp(String email) async {
    try {
      //Verifica si hay usuario autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'unauthenticated',
          message: 'No hay usuario autenticado.',
        );
      }

      print('Usuario autenticado: ${user.uid}');

      //Generar código OTP
      final code = _generateOtpCode();
      print('Código OTP generado: $code');

      //Guardar temporalmente el OTP localmente con estado "pendiente"
      final otpBox = await Hive.openBox<OtpInfo>('otp_info');
      final otpInfo = OtpInfo(
        otpCode: code,
        timestamp: DateTime.now(),
        pendingSend: true,
      );
      await otpBox.put(email, otpInfo);

      //Forzar renovación del token de autenticación
      await user.getIdToken(true);

      //Llamar a la función Cloud (protegida con contexto.auth)
      final callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
      final result = await callable.call({
        'email': email,
        'code': code,
      });

      print('OTP enviado con éxito: ${result.data}');

      //Marcar como enviado exitosamente
      final updatedOtpInfo = otpInfo.copyWith(pendingSend: false);
      await otpBox.put(email, updatedOtpInfo);
    } catch (e) {
      print('Error al enviar OTP: $e');
      rethrow;
    }
  }

  static String _generateOtpCode() {
    final random = Random();
    return (random.nextInt(900000) + 100000).toString(); // 6 dígitos
  }
}
