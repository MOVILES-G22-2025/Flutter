import 'package:hive/hive.dart';

part 'draft_product.g.dart';

@HiveType(typeId: 3)
class DraftProduct extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String userId;

  @HiveField(6)
  final DateTime createdAt;

  DraftProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.userId,
    required this.createdAt,
  });
}