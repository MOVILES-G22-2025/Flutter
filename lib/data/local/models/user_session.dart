/// DTO que representa la sesión de usuario almacenada localmente.
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

  /// Opcional: para facilitar convertir a JSON (si lo necesitas)
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'isLoggedIn': isLoggedIn ? 'true' : 'false',
  };

  /// Opcional: para restaurar desde JSON
  factory UserSessionModel.fromJson(Map<String, dynamic> json) {
    return UserSessionModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      isLoggedIn: json['isLoggedIn'] == 'true',
    );
  }
}