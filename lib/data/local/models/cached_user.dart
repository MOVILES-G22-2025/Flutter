import 'package:hive/hive.dart';

part 'cached_user.g.dart';
@HiveType(typeId: 20)
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
  @HiveField(5) // Nuevo campo
  final String localPhotoPath;

  CachedUser({
    required this.id,
    required this.name,
    required this.career,
    required this.semester,
    required this.photoUrl,
    required this.localPhotoPath, // <-- Aquí
  });
}
