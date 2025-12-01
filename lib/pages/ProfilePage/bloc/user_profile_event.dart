sealed class UserProfileEvent {}

final class GetUserEvent extends UserProfileEvent {
  final String userId;

  GetUserEvent({required this.userId});
}

final class UpdateAvatarEvent extends UserProfileEvent {
  final String userId;
  final String filePath;

  UpdateAvatarEvent({required this.userId, required this.filePath});
}
