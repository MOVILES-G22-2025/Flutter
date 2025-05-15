class User {
  final String id;
  final String name;
  final String career;
  final String semester;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.career,
    required this.semester,
    required this.email,
  });

  // ---------- SQLite helpers ----------

  Map<String, dynamic> toMap() {
    return {
      'id'       : id,
      'name'     : name,
      'career'   : career,
      'semester' : semester,
      'email'    : email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id        : map['id'],
      name      : map['name'],
      career    : map['career'],
      semester  : map['semester'],
      email     : map['email'],
    );
  }
}