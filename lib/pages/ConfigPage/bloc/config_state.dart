import 'package:ting_box/models/config_model.dart';

import '../../../models/bank.dart';

sealed class ConfigState {}

final class ConfigInitial extends ConfigState {}

final class ConfigLoading extends ConfigState {}

final class ConfigLoaded extends ConfigState {
  final ConfigModel config;

  ConfigLoaded({required this.config});
}

final class ConfigFailure extends ConfigState {
  final String message;

  ConfigFailure({required this.message});
}

final class ConfigSaveSuccess extends ConfigState {
  final ConfigModel config;
  final String message;
  ConfigSaveSuccess({required this.config, required this.message});
}

final class BankLoaded extends ConfigState {
  final List<Bank> banks;

  BankLoaded({required this.banks});
}

