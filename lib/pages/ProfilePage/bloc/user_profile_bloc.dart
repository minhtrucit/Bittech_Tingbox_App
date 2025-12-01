import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/services/user_services.dart';
import '../../../ting_box.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserService userService;

  UserProfileBloc({required this.userService}) : super(UserProfileInitial()) {
    on<GetUserEvent>(_onGetUser);
    on<UpdateAvatarEvent>(_onUpdateAvatar);
  }

  Future<void> _onGetUser(
    GetUserEvent event,
    Emitter<UserProfileState> emit,
  ) async {
    debugPrint(
      "🚀 UserProfileBloc: Processing GetUserEvent for userId: ${event.userId}",
    );
    emit(UserProfileLoading());
    try {
      final user = await userService.getUser(userId: event.userId);
      debugPrint("✅ UserProfileBloc: User fetched: $user");
      if (user == null) {
        debugPrint("⚠️ UserProfileBloc: User is null");
        emit(UserProfileFailure("User not found"));
        return;
      }
      emit(UserProfileSuccess(user: user));
      debugPrint("🎉 UserProfileBloc: Emitted UserProfileSuccess");
    } catch (e) {
      debugPrint("❌ UserProfileBloc: Error fetching user: $e");
      emit(UserProfileFailure(e.toString()));
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatarEvent event,
    Emitter<UserProfileState> emit,
  ) async {
    debugPrint("🚀 UserProfileBloc: Processing UpdateAvatarEvent");

    final currentState = state;
    if (currentState is! UserProfileSuccess) {
      debugPrint("⚠️ UserProfileBloc: Cannot update avatar, user not loaded");
      return;
    }

    emit(UserProfileSuccess(user: currentState.user, isAvatarUpdating: true));

    try {
      final user = await userService.updateAvatar(
        userId: event.userId,
        filePath: event.filePath,
      );
      if (user != null) {
        emit(UserProfileSuccess(user: user, isAvatarUpdating: false));
      } else {
        // Revert to previous state with error message if needed, or just stop loading
        emit(
          UserProfileSuccess(user: currentState.user, isAvatarUpdating: false),
        );
        // Optionally emit a side-effect or error state if you had one that didn't replace the UI
      }
    } catch (e) {
      debugPrint("❌ UserProfileBloc: Error updating avatar: $e");
      emit(
        UserProfileSuccess(user: currentState.user, isAvatarUpdating: false),
      );
      // emit(UserProfileFailure(e.toString())); // This would replace the UI, so avoid it or handle it differently
    }
  }
}
