class Doctor {
  final String id;
  final String name;
  final String? email;
  final String? photo;
  final String? specialization;
  final bool? isAvailable;

  Doctor({
    required this.id,
    required this.name,
    this.email,
    this.photo,
    this.specialization,
    this.isAvailable,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      photo: json['photo'],
      specialization: json['specialization'],
      isAvailable: json['isAvailable'],
    );
  }
} 