import 'dart:convert';

class User {
  final String id;
  final String phone;
  final String email;
  final String? token;
  final String? name;

  User( {
    required this.id,
    required this.phone,
    required this.email,
    this.token,
    this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      token: json['token']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      if (token != null) 'token': token,
      if (name != null) 'name': name,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
