import 'package:ting_box/models/config_model.dart';

sealed class ConfigEvent {}

final class GetConfigEvent extends ConfigEvent {
  final String userId;

  GetConfigEvent({required this.userId});
}

final class SaveConfigEvent extends ConfigEvent {
  final ConfigModel config;

  SaveConfigEvent({required this.config});
}

final class GetBankEvent extends ConfigEvent {
  GetBankEvent();
}

