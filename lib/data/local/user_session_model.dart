class UserSessionModel {
  final String uid;
  final String email;
  final String name;
  final bool isLoggedIn;

  UserSessionModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.isLoggedIn,
  });
}
