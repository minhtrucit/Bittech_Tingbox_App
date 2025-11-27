import 'package:ting_box/models/bank.dart';
import 'package:ting_box/models/user.dart';

enum PrintMode { none, auto, manual }

class ConfigModel {
  final int? id;
  final String? unitName;
  final String? sepayApiKey;
  final PrintMode printMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ConfigUser> configUsers;
  final List<ConfigBankAccount> bankAccounts;

  ConfigModel({
    this.id,
    this.unitName,
    this.sepayApiKey,
    required this.printMode,
    this.createdAt,
    this.updatedAt,
    this.configUsers = const [],
    this.bankAccounts = const [],
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      id: json['id'],
      unitName: json['unitName']?.toString(),
      sepayApiKey: json['sepayApiKey']?.toString(),
      printMode: PrintMode.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['printMode']?.toString() ?? 'NONE').toUpperCase(),
        orElse: () => PrintMode.none,
      ),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      configUsers:
          (json['configUsers'] as List<dynamic>?)
              ?.map((e) => ConfigUser.fromJson(e))
              .toList() ??
          [],
      bankAccounts:
          (json['bankAccounts'] as List<dynamic>?)
              ?.map((e) => ConfigBankAccount.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitName': unitName,
      'sepayApiKey': sepayApiKey,
      'printMode': printMode.name.toUpperCase(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'configUsers': configUsers.map((e) => e.toJson()).toList(),
      'bankAccounts': bankAccounts.map((e) => e.toJson()).toList(),
    };
  }
}

class ConfigUser {
  final int id;
  final int configId;
  final int userId;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;

  ConfigUser({
    required this.id,
    required this.configId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory ConfigUser.fromJson(Map<String, dynamic> json) {
    return ConfigUser(
      id: json['id'] ?? 0,
      configId: json['configId'] ?? 0,
      userId: json['userId'] ?? 0,
      role: json['role'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'configId': configId,
      'userId': userId,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}

class ConfigBankAccount {
  final int id;
  final int configId;
  final int bankId;
  final String accountNumber;
  final String accountName;
  final bool isDefault;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Bank? bank;

  ConfigBankAccount({
    required this.id,
    required this.configId,
    required this.bankId,
    required this.accountNumber,
    required this.accountName,
    required this.isDefault,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.bank,
  });

  factory ConfigBankAccount.fromJson(Map<String, dynamic> json) {
    return ConfigBankAccount(
      id: json['id'] ?? 0,
      configId: json['configId'] ?? 0,
      bankId: json['bankId'] ?? 0,
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      bank:
          json['bank'] != null
              ? Bank(
                id: json['bank']['id'],
                name: json['bank']['name'],
                code: json['bank']['code'],
                shortName: json['bank']['shortName'] ?? '',
                logo: json['bank']['logo'],
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'configId': configId,
      'bankId': bankId,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'bank': bank?.toJson(),
    };
  }
}
