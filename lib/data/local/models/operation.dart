import 'package:hive/hive.dart';

part 'operation.g.dart';      // para hive_generator

@HiveType(typeId: 0)
class Operation extends HiveObject {
  @HiveField(0) String id;           // uuid
  @HiveField(1) OperationType type;  // enum
  @HiveField(2) Map<String, dynamic> payload;
  @HiveField(3) DateTime ts;

  Operation({
    required this.id,
    required this.type,
    required this.payload,
    DateTime? ts,
  }) : ts = ts ?? DateTime.now();
}

@HiveType(typeId: 1)
enum OperationType {
  @HiveField(0) toggleFavorite,
  // otros vendrán luego (createProduct, etc.)
}