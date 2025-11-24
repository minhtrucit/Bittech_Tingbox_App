
import '../../../models/user.dart';

sealed class UserProfileState {}

final class UserProfileInitial extends UserProfileState {}

final class UserProfileLoading extends UserProfileState {}

final class UserProfileFailure extends UserProfileState {
  final String message;
  UserProfileFailure(this.message);
}

final class UserProfileSuccess extends UserProfileState {
  final User user;
  UserProfileSuccess({required this.user});
}

