// lib/data/local/models/operation.dart
import 'package:hive/hive.dart';

part 'operation.g.dart';

@HiveType(typeId: 0)
class Operation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  OperationType type;

  @HiveField(2)
  Map<String, dynamic> payload;

  @HiveField(3)
  DateTime ts;

  Operation({
    required this.id,
    required this.type,
    required this.payload,
    DateTime? ts,
  }) : ts = ts ?? DateTime.now();
}

@HiveType(typeId: 1)
enum OperationType {
  @HiveField(0)
  toggleFavorite,

  @HiveField(1)
  sendMessage,     // <-- nuevo tipo de operación
}
