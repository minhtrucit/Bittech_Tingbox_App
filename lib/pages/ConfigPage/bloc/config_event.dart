import 'package:ting_box/models/config_model.dart';

sealed class ConfigEvent {}

final class GetConfigEvent extends ConfigEvent {
  final int userId;

  GetConfigEvent({required this.userId});
}

final class SaveConfigEvent extends ConfigEvent {
  final ConfigModel config;

  SaveConfigEvent({required this.config});
}
