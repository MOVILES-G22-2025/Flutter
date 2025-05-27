part of 'otp_info.dart';

class OtpInfoAdapter extends TypeAdapter<OtpInfo> {
  @override
  final int typeId = 5;

  @override
  OtpInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OtpInfo(
      otpCode: fields[0] as String,
      timestamp: fields[1] as DateTime,
      pendingSend: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OtpInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.otpCode)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.pendingSend);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OtpInfoAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}