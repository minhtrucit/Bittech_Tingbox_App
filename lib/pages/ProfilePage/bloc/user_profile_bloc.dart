import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/services/user_services.dart';
import '../../../ting_box.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserService userService;

  UserProfileBloc({required this.userService}) : super(UserProfileInitial()) {
    on<GetUserEvent>(_onGetUser);
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
}
