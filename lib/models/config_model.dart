import 'package:ting_box/models/user.dart';

class ConfigModel {
  final int? id;
  final int userId;
  final String unitName;
  final String bankAccount;
  final String accountName;
  final String sepayApiKey;
  final int printMode; // 0: KHONG_IN, 1: TU_DONG
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;

  ConfigModel({
    this.id,
    required this.userId,
    required this.unitName,
    required this.bankAccount,
    required this.accountName,
    required this.sepayApiKey,
    required this.printMode,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      id: json['id'],
      userId: json['userId'] ?? 0,
      unitName: json['unitName']?.toString() ?? '',
      bankAccount: json['bankAccount']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      sepayApiKey: json['sepayApiKey']?.toString() ?? '',
      printMode: json['printMode'] ?? 1,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'unitName': unitName,
      'bankAccount': bankAccount,
      'accountName': accountName,
      'sepayApiKey': sepayApiKey,
      'printMode': printMode,
    };
  }
}
