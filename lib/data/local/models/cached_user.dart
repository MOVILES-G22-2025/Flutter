import 'package:hive/hive.dart';

@HiveType(typeId: 20) // Usa un typeId único
class CachedUser extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String career;
  @HiveField(3)
  final String semester;
  @HiveField(4)
  final String photoUrl;

  CachedUser({
    required this.id,
    required this.name,
    required this.career,
    required this.semester,
    required this.photoUrl,
  });
}
