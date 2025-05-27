
import 'package:hive/hive.dart';
import 'package:senemarket/data/local/models/cached_user.dart';

class LocalUserCacheRepository {
  static const String _boxName = 'cached_users';

  Future<Box<CachedUser>> openBox() async {
    return await Hive.openBox<CachedUser>(_boxName);
  }

  Future<void> saveUser(CachedUser user) async {
    final box = await openBox();
    await box.put(user.id, user);
  }

  Future<CachedUser?> getUser(String userId) async {
    final box = await openBox();
    return box.get(userId);
  }
}
