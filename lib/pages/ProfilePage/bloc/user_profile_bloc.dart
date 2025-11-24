import 'package:bloc/bloc.dart';
import 'package:ting_box/services/user_services.dart';
import '../../../ting_box.dart';



class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserService userService;

  UserProfileBloc({required this.userService})
    : super(UserProfileInitial()) {
    on<GetUserEvent>(_onGetUser);
  }

  Future<void> _onGetUser(GetUserEvent event, Emitter<UserProfileState> emit) async {
    emit(UserProfileLoading());
    try {
      final user = await userService.getUser(userId: event.userId);
      emit(UserProfileSuccess(user: user));
    } catch (e) {
      emit(UserProfileFailure(e.toString()));
    }
  }
}
