sealed class UserProfileEvent {}

final class GetUserEvent extends UserProfileEvent {
  final String userId;

  GetUserEvent({required this.userId});
}
