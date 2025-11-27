import 'dart:io';

import 'package:ting_box/models/config_model.dart';

sealed class ConfigEvent {}

final class GetConfigEvent extends ConfigEvent {
  final String userId;

  GetConfigEvent({required this.userId});
}

final class UpdateConfigEvent extends ConfigEvent {
  final ConfigModel config;
  final File? logoFile;

  UpdateConfigEvent({required this.config, this.logoFile});
}

final class GetBankEvent extends ConfigEvent {
  GetBankEvent();
}

final class GetSepayInfoEvent extends ConfigEvent {
  GetSepayInfoEvent();
}

final class LoadSepayInfoFromLocalEvent extends ConfigEvent {
  LoadSepayInfoFromLocalEvent();
}

final class CreateConfigEvent extends ConfigEvent {
  final ConfigModel config;

  CreateConfigEvent({required this.config});
}

final class CreateOrUpdateBankAccountEvent extends ConfigEvent {
  final int configId;
  final int bankId;
  final String accountNumber;
  final String accountName;
  final bool isDefault;
  final bool isActive;

  CreateOrUpdateBankAccountEvent({
    required this.configId,
    required this.bankId,
    required this.accountNumber,
    required this.accountName,
    this.isDefault = true,
    this.isActive = true,
  });
}
