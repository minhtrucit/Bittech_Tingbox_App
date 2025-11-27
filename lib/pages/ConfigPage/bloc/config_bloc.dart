import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/services/config_service.dart';
import 'config_event.dart';
import 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final ConfigService configService;

  ConfigBloc({required this.configService}) : super(ConfigInitial()) {
    on<GetConfigEvent>(_onGetConfig);
    on<SaveConfigEvent>(_onSaveConfig);
  }

  Future<void> _onGetConfig(
    GetConfigEvent event,
    Emitter<ConfigState> emit,
  ) async {
    emit(ConfigLoading());
    try {
      final config = await configService.getConfig(event.userId);
      if (config != null) {
        debugPrint('[ConfigBloc] Config: ${config.toJson()}');
        emit(ConfigLoaded(config: config));
      } else {
        // If no config found, maybe emit initial or empty loaded state?
        // For now, let's assume failure or just empty
        emit(ConfigFailure(message: "Không tìm thấy cấu hình"));
      }
    } catch (e) {
      emit(ConfigFailure(message: e.toString()));
    }
  }

  Future<void> _onSaveConfig(
    SaveConfigEvent event,
    Emitter<ConfigState> emit,
  ) async {
    emit(ConfigLoading());
    try {
      final result = await configService.saveConfig(event.config);
      if (result['status'] == 'success') {
        emit(
          ConfigSaveSuccess(config: event.config, message: result['message']),
        );
        // Optionally reload config after save
        if (event.config.configUsers.isNotEmpty) {
          add(
            GetConfigEvent(
              userId: event.config.configUsers.first.userId.toString(),
            ),
          );
        }
      } else {
        emit(ConfigFailure(message: result['message']));
      }
    } catch (e) {
      emit(ConfigFailure(message: e.toString()));
    }
  }
}
