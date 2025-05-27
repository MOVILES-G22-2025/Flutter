import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/local/models/otp_info.dart';

class OTPVerificationViewModel extends ChangeNotifier {
  final String email;
  final _hiveBox = Hive.box<OtpInfo>('otp_info');

  String _code = '';
  bool _isVerifying = false;
  String? _errorMessage;
  int _secondsLeft = 300;
  bool _canResend = false;
  StreamSubscription<int>? _streamSubscription;

  bool get isVerifying => _isVerifying;
  bool get canResend => _canResend;
  String? get errorMessage => _errorMessage;
  String get timeRemainingFormatted =>
      '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

  OTPVerificationViewModel(this.email);

  void updateCode(String code) {
    _code = code;
    notifyListeners();
  }

  void startTimer() {
    _canResend = false;
    _streamSubscription?.cancel();
    _streamSubscription = _countdownStream(300).listen((seconds) {
      _secondsLeft = seconds;
      if (seconds == 0) _canResend = true;
      notifyListeners();
    });
  }

  Stream<int> _countdownStream(int start) async* {
    for (int i = start; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      yield i;
    }
  }

  Future<void> verifyCode() async {
    _isVerifying = true;
    _errorMessage = null;
    notifyListeners();

    // Simulación de validación forzada
    if (_code == "456386") {
      await Future.delayed(const Duration(milliseconds: 700));
      if (navigatorKey.currentState?.mounted ?? false) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } else {
      _errorMessage = 'Incorrect code.';
    }

    _isVerifying = false;
    notifyListeners();
  }

  Future<void> resendCode() async {
    final newCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final info = OtpInfo(
      otpCode: newCode,
      timestamp: DateTime.now(),
      pendingSend: true,
    );

    try {
      await _hiveBox.put('otp', info);

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        await _sendCodeByEmail(newCode)
            .then((_) => print('OTP enviado exitosamente'))
            .catchError((e) => print('Error enviando OTP: $e'))
            .whenComplete(() => print('Envío completado (éxito o error)'));
      } else {
        Connectivity().onConnectivityChanged.listen((status) {
          if (status != ConnectivityResult.none && _hiveBox.get('pendingSend') == true) {
            _sendCodeByEmail(newCode)
                .then((_) => print('OTP reenviado tras reconexión'))
                .catchError((e) => print('Error tras reconexión: $e'));
          }
        });
      }
    } catch (e) {
      print('Error general en resendCode: $e');
    } finally {
      _secondsLeft = 300;
      _canResend = false;
      startTimer();
      notifyListeners();
    }
  }
  Future<void> _sendCodeByEmail(String code) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
      await callable.call({'email': email, 'code': code});
      final info = _hiveBox.get('otp');
      if (info != null) {
        info.pendingSend = false;
        await info.save();
      }
    } catch (e) {
      if (kDebugMode) print('Error sending OTP: $e');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
