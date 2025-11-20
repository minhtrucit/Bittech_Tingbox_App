import 'package:bloc/bloc.dart';
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
    emit(AuthLoading());
    try {
      // 1️⃣ Gọi API
      final result = await authService.login(event.phone, event.password);

      if (result['success'] == true && result['user'] != null) {
        final user = result['user'] as User;

        // 2️⃣ Lưu local
        await UserRepository.saveUser(user);

        // 3️⃣ Emit success
        emit(AuthSuccess(user));
      } else {
        emit(AuthFailure(result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
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
