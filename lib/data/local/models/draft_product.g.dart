// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DraftProductAdapter extends TypeAdapter<DraftProduct> {
  @override
  final int typeId = 3;

  @override
  DraftProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DraftProduct(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      category: fields[4] as String,
      userId: fields[5] as String,
      createdAt: fields[6] as DateTime?,
      imagePaths: (fields[7] as List?)?.cast<String>(),
      lastUpdated: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DraftProduct obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.imagePaths)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
