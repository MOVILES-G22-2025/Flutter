import 'package:hive/hive.dart';
part 'otp_info.g.dart';

@HiveType(typeId: 11)
class OtpInfo extends HiveObject {
  @HiveField(0)
  final String otpCode;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  bool pendingSend;

  OtpInfo({
    required this.otpCode,
    required this.timestamp,
    this.pendingSend = true,
  });

  OtpInfo copyWith({
    String? otpCode,
    DateTime? timestamp,
    bool? pendingSend,
  }) {
    return OtpInfo(
      otpCode: otpCode ?? this.otpCode,
      timestamp: timestamp ?? this.timestamp,
      pendingSend: pendingSend ?? this.pendingSend,
    );
  }

  // El código expira en 5 minutos
  bool get isExpired => DateTime.now().difference(timestamp).inMinutes >= 5;
}