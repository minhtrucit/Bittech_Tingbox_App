import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../models/user.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/auth_services.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final UserRepository userRepository;

  AuthBloc({required this.authService, required this.userRepository}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    debugPrint('[AuthBloc] _onLogin: received LoginEvent with phone=${event.phone}');

    // 1️⃣ Emit loading
    emit(AuthLoading());
    debugPrint('[AuthBloc] _onLogin: AuthLoading emitted');

    try {
      // 2️⃣ Gọi API
      debugPrint('[AuthBloc] _onLogin: calling authService.login...');
      final result = await authService.login(event.phone, event.password);
      debugPrint('[AuthBloc] _onLogin: authService.login completed, result=$result');

      // 3️⃣ Kiểm tra kết quả
      if (result['status'] == 'success' && result['user'] != null) {
        final user = result['user'] as User;
        debugPrint('[AuthBloc] _onLogin: login success, user=${user.toJson()}');

        // 4️⃣ Lưu user vào local
        debugPrint('[AuthBloc] _onLogin: saving user locally...');
        await UserRepository.saveUser(user);
        debugPrint('[AuthBloc] _onLogin: user saved');

        // 5️⃣ Emit success
        emit(AuthSuccess(user));
        debugPrint('[AuthBloc] _onLogin: AuthSuccess emitted');
      } else {
        final message = result['message'] ?? 'Login failed';
        debugPrint('[AuthBloc] _onLogin: login failed, message=$message');

        // Emit failure
        emit(AuthFailure(message));
        debugPrint('[AuthBloc] _onLogin: AuthFailure emitted');
      }
    } catch (e, st) {
      // 6️⃣ Catch exception
      debugPrint('[AuthBloc] _onLogin: exception caught -> $e\n$st');

      emit(AuthFailure(e.toString()));
      debugPrint('[AuthBloc] _onLogin: AuthFailure emitted due to exception');
    }
  }



  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await authService.logout();
      await UserRepository.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure('Logout failed: $e'));
    }
  }
}
