import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/services/config_service.dart';
import 'package:ting_box/ting_box.dart';
import 'config_event.dart';
import 'config_state.dart';
import 'package:ting_box/models/config_model.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final ConfigService configService;

  ConfigBloc({required this.configService}) : super(ConfigInitial()) {
    on<GetConfigEvent>(_onGetConfig);
    on<UpdateConfigEvent>(_onUpdateConfig);
    on<CreateConfigEvent>(_onCreateConfig);
    on<GetBankEvent>(_onGetBank);
    on<CreateOrUpdateBankAccountEvent>(_onCreateOrUpdateBankAccount);
    on<GetSepayInfoEvent>(_onGetSepayInfo);
    on<LoadSepayInfoFromLocalEvent>(_onLoadSepayInfoFromLocal);
  }

  Future<void> _onLoadSepayInfoFromLocal(
    LoadSepayInfoFromLocalEvent event,
    Emitter<ConfigState> emit,
  ) async {
    try {
      final url = await configService.getSepayUrlFromLocal();
      if (url != null && url.isNotEmpty) {
        emit(SepayInfoLoaded(url: url));
      }
    } catch (e) {
      debugPrint('Error loading sepay info from local: $e');
    }
  }

  Future<void> _onGetSepayInfo(
    GetSepayInfoEvent event,
    Emitter<ConfigState> emit,
  ) async {
    try {
      final data = await configService.getSepayInfo();
      if (data.isNotEmpty) {
        emit(SepayInfoLoaded(url: data['url'] ?? ''));
      } else {
        emit(ConfigFailure(message: 'Không lấy được thông tin Sepay'));
      }
    } catch (e) {
      emit(ConfigFailure(message: e.toString()));
    }
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
        UserRepository.saveConfigId(config.id.toString());
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

  Future<void> _onUpdateConfig(
    UpdateConfigEvent event,
    Emitter<ConfigState> emit,
  ) async {
    emit(ConfigLoading());
    try {
      final result = await configService.updateConfig(event.config);
      if (result['status'] == 'success') {
        emit(
          ConfigUpdateSuccess(config: event.config, message: result['message']),
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

  Future<void> _onCreateConfig(
    CreateConfigEvent event,
    Emitter<ConfigState> emit,
  ) async {
    emit(ConfigLoading());
    try {
      final result = await configService.createConfig(event.config);
      if (result['status'] == 'success') {
        // Try to parse the created config from result if available to get the ID
        ConfigModel createdConfig = event.config;
        if (result['data'] != null) {
          try {
            // Check if data is Map or needs parsing
            final data = result['data'];
            if (data is Map<String, dynamic>) {
              createdConfig = ConfigModel.fromJson(data);
            }
          } catch (e) {
            debugPrint('Error parsing created config: $e');
          }
        }

        emit(
          ConfigCreateSuccess(
            config: createdConfig,
            message: result['message'],
          ),
        );
      } else {
        emit(ConfigFailure(message: result['message']));
      }
    } catch (e) {
      emit(ConfigFailure(message: e.toString()));
    }
  }

  Future<void> _onGetBank(GetBankEvent event, Emitter<ConfigState> emit) async {
    try {
      final banks = await configService.getBanks();
      debugPrint(
        '[ConfigBloc] Banks: ${banks.map((e) => e.toJson()).toList()}',
      );
      emit(BankLoaded(banks: banks));
    } catch (e) {
      debugPrint('Error loading banks: $e');
    }
  }

  Future<void> _onCreateOrUpdateBankAccount(
    CreateOrUpdateBankAccountEvent event,
    Emitter<ConfigState> emit,
  ) async {
    try {
      final result = await configService.createOrUpdateBankAccount(
        configId: event.configId,
        bankId: event.bankId,
        accountNumber: event.accountNumber,
        accountName: event.accountName,
        isDefault: event.isDefault,
        isActive: event.isActive,
      );

      if (result['status'] == 'success') {
        emit(
          BankAccountSuccess(
            message: result['message'] ?? 'Cập nhật ngân hàng thành công',
          ),
        );
      } else {
        emit(
          ConfigFailure(message: result['message'] ?? 'Lỗi cập nhật ngân hàng'),
        );
      }
    } catch (e) {
      debugPrint('Error creating/updating bank account: $e');
      emit(ConfigFailure(message: e.toString()));
    }
  }
}
