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

final class ConfigUpdateSuccess extends ConfigState {
  final ConfigModel config;
  final String message;
  ConfigUpdateSuccess({required this.config, required this.message});
}

final class ConfigCreateSuccess extends ConfigState {
  final ConfigModel config;
  final String message;
  ConfigCreateSuccess({required this.config, required this.message});
}

final class BankLoaded extends ConfigState {
  final List<Bank> banks;

  BankLoaded({required this.banks});
}

final class BankAccountSuccess extends ConfigState {
  final String message;

  BankAccountSuccess({required this.message});
}

final class SepayInfoLoaded extends ConfigState {
  final String url;
  final String sepayApiKey;
  SepayInfoLoaded({required this.url, required this.sepayApiKey});
}
