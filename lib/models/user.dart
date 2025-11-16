class User {
  final String id;
  final String fullName;
  final String email;
  final String password; // In production, never store plain passwords

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
  });

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  @override
  String toString() => 'User(id: $id, fullName: $fullName, email: $email)';
}
