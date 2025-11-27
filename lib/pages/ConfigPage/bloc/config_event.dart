import 'package:ting_box/models/config_model.dart';

sealed class ConfigEvent {}

final class GetConfigEvent extends ConfigEvent {
  final String userId;

  GetConfigEvent({required this.userId});
}

final class UpdateConfigEvent extends ConfigEvent {
  final ConfigModel config;
  final String userId;

  UpdateConfigEvent({required this.config, required this.userId});
}

final class GetBankEvent extends ConfigEvent {
  GetBankEvent();
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
