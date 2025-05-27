// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedUserAdapter extends TypeAdapter<CachedUser> {
  @override
  final int typeId = 20;

  @override
  CachedUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUser(
      id: fields[0] as String,
      name: fields[1] as String,
      career: fields[2] as String,
      semester: fields[3] as String,
      photoUrl: fields[4] as String,
      localPhotoPath: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedUser obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.career)
      ..writeByte(3)
      ..write(obj.semester)
      ..writeByte(4)
      ..write(obj.photoUrl)
      ..writeByte(5)
      ..write(obj.localPhotoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
