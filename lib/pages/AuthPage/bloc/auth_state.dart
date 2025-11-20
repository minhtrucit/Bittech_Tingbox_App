import 'package:ting_box/models/user.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}

final class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

final class AuthLogoutSuccess extends AuthState {
  final bool success;
  AuthLogoutSuccess({required this.success});
}
