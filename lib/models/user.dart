import 'dart:convert';

class User {
  final int id;
  final String email;
  final String userName;
  final String phone;
  final String? avatar;
  final bool isActive;
  final String refreshToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int roleId;
  final Role role;
  final String? token; 
  bool? isDevMode;

  User({
    required this.id,
    required this.email,
    required this.userName,
    required this.phone,
    this.avatar,
    required this.isActive,
    required this.refreshToken,
    required this.createdAt,
    required this.updatedAt,
    required this.roleId,
    required this.role,
    this.token,
    this.isDevMode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      userName: json['userName'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      isActive: json['isActive'] ?? false,
      refreshToken: json['expenseManagerRefreshToken'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      roleId: json['roleId'] ?? 0,
      role: Role.fromJson(Map<String, dynamic>.from(json['role'] ?? {})),
      token: json['expenseManagerAccessToken']?.toString(),
      isDevMode: json['isDevMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'userName': userName,
      'phone': phone,
      'avatar': avatar,
      'isActive': isActive,
      'refreshToken': refreshToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'roleId': roleId,
      'role': role.toJson(),
      'isDevMode': isDevMode,
      if (token != null) 'token': token,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class Role {
  final int id;
  final String name;
  final String description;
  final Permissions permissions;

  Role({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      permissions: Permissions.fromJson(Map<String, dynamic>.from(json['permissions'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions.toJson(),
    };
  }
}

class Permissions {
  final Map<String, List<String>> perms;

  Permissions({required this.perms});

  factory Permissions.fromJson(Map<String, dynamic> json) {
    final map = <String, List<String>>{};
    json.forEach((key, value) {
      map[key] = List<String>.from(value ?? []);
    });
    return Permissions(perms: map);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    perms.forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  List<String> get(String key) => perms[key] ?? [];
}
