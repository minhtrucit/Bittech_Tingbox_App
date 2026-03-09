import 'package:flutter/material.dart';
import 'package:ting_box/models/bank.dart';
import 'package:ting_box/models/user.dart';

enum PrintMode { none, auto, manual }

enum SubscriptionPlan { basic, premium }

enum BusinessMode {
  financeOnly, // Chỉ quản lý thu chi
  retail, // Bán hàng không bàn (Cửa hàng, Take-away)
  fnb, // Bán hàng có bàn (Nhà hàng, Cafe)
}

class ConfigModel {
  final int? id;
  final String? unitName;
  final String? sepayApiKey;
  final PrintMode printMode;
  final BusinessMode businessMode;
  SubscriptionPlan? subscriptionPlan;
  final String? logo;
  final String? phone;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ConfigUser> configUsers;
  final List<ConfigBankAccount> bankAccounts;

  ConfigModel({
    this.id,
    this.unitName,
    this.sepayApiKey,
    required this.printMode,
    this.businessMode = BusinessMode.fnb,
    this.subscriptionPlan,
    this.logo,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.configUsers = const [],
    this.bankAccounts = const [],
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    debugPrint(json.toString());
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
      businessMode: BusinessMode.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['businessMode']?.toString() ?? 'FNB').toUpperCase(),
        orElse: () => BusinessMode.fnb,
      ),
      logo: json['logo']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
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
      subscriptionPlan: SubscriptionPlan.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['subscriptionPlan']?.toString() ?? 'BASIC').toUpperCase(),
        orElse: () => SubscriptionPlan.basic,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitName': unitName,
      'sepayApiKey': sepayApiKey,
      'printMode': printMode.name.toUpperCase(),
      'businessMode': businessMode.name.toUpperCase(),
      'logo': logo,
      'phone': phone,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'subscriptionPlan': subscriptionPlan?.name.toUpperCase() ?? 'BASIC',
      // Don't send bankAccounts and configUsers - they are handled separately
    };
  }

  bool checkPremium() {
    return subscriptionPlan == SubscriptionPlan.premium;
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
      // Don't send nested user object to API
    };
  }
}

class ConfigBankAccount {
  final int id;
  final int configId;
  final int bankId;
  final String accountNumber;
  final String accountName;
  final String? qrCode;
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
    this.qrCode,
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
      qrCode: json['qrCode'] ?? '',
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
                transferSupported: json['bank']['transferSupported'] ?? 0,
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
      'qrCode': qrCode,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      // Don't send nested bank object to API
    };
  }
}
