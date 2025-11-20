import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/ting_box.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final AuthBloc authBloc;
  bool isPhoneValid = true;
  bool _isLoadingOverlay = false; // để kiểm soát overlay

  @override
  void initState() {
    super.initState();
    authBloc = BlocProvider.of<AuthBloc>(context);
    debugPrint('[Auth] initState: AuthBloc initialized');
  }

  void onPhoneChanged(String value) {
    setState(() {
      isPhoneValid = isValidPhone(value);
    });
    debugPrint('[Auth] onPhoneChanged: $value, isPhoneValid=$isPhoneValid');
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^[0-9]{6,15}$');
    return regex.hasMatch(phone);
  }

  void handleSubmit() {
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      debugPrint('[Auth] handleSubmit: Missing phone or password');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin')),
      );
      return;
    }

    if (!isPhoneValid) {
      debugPrint('[Auth] handleSubmit: Invalid phone number');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }

    debugPrint('[Auth] handleSubmit: Sending LoginEvent phone=$phone');
    authBloc.add(LoginEvent(phone: phone, password: pass));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        debugPrint('[AuthListener] state changed: $state');

        if (state is AuthLoading) {
          setState(() => _isLoadingOverlay = true);
          debugPrint('[AuthListener] AuthLoading: show overlay');
        } else {
          setState(() => _isLoadingOverlay = false);
          debugPrint('[AuthListener] AuthLoading finished: hide overlay');
        }

        if (state is AuthSuccess) {
          debugPrint('[AuthListener] AuthSuccess: Navigate to BasePage');
          // Delay 200ms để overlay loading ẩn trước khi chuyển màn hình
          await Future.delayed(const Duration(milliseconds: 200));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BasePage()),
          );
        }

        if (state is AuthFailure) {
          debugPrint('[AuthListener] AuthFailure: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại: ${state.message}')),
          );
        }
      },
      child: Stack(
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return AuthPage(
                onPhoneChanged: onPhoneChanged,
                onLogin: handleSubmit,
                isPhoneValid: isPhoneValid,
                phoneController: phoneController,
                passwordController: passwordController,
              );
            },
          ),
          if (_isLoadingOverlay)
            Stack(
              children: [
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.black38,
                ),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryBlue,),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
