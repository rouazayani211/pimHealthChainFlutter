class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? photo;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      photo: json['photo'],
    );
  }
}
