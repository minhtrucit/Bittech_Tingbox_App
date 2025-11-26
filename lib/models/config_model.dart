import 'package:ting_box/models/bank.dart';
import 'package:ting_box/models/user.dart';

enum PrintMode { none, auto, manual }

class ConfigModel {
  final int? id;
  final int userId;
  final String? unitName;
  final String bankAccount;
  final String accountName;
  final String sepayApiKey;
  final PrintMode printMode; // 0: KHONG_IN, 1: TU_DONG
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;
  final int bankId;
  final Bank? bank;

  ConfigModel({
    this.id,
    required this.userId,
    this.unitName,
    required this.bankAccount,
    required this.accountName,
    required this.sepayApiKey,
    required this.printMode,
    this.createdAt,
    this.updatedAt,
    this.user,
    required this.bankId,
    this.bank,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      id: json['id'],
      userId: json['userId'] ?? 0,
      unitName: json['unitName']?.toString() ?? '',
      bankAccount: json['bankAccount']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      sepayApiKey: json['sepayApiKey']?.toString() ?? '',
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
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      bankId: json['bankId'] ?? 0,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'unitName': unitName,
      'bankAccount': bankAccount,
      'accountName': accountName,
      'sepayApiKey': sepayApiKey,
      'printMode': printMode.name.toUpperCase(),
      'bankId': bankId,
      'bank': bank?.toJson(),
    };
  }
}


