sealed class AuthEvent {}

final class LoginEvent extends AuthEvent {
  final String phone;
  final String password;

  LoginEvent({required this.phone, required this.password});
}

final class LogoutEvent extends AuthEvent {

  LogoutEvent();
}
