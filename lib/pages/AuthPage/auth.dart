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

  @override
  void initState() {
    authBloc = BlocProvider.of<AuthBloc>(context);
    super.initState();
  }

  void onPhoneChanged(String value) {
    setState(() {
      isPhoneValid = isValidPhone(value);
    });
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^[0-9]{6,15}$');
    return regex.hasMatch(phone);
  }

  void handleSubmit() {
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      showSnack("Vui lòng nhập đủ thông tin");
      return;
    }

    if (!isPhoneValid) {
      showSnack("Số điện thoại không hợp lệ");
      return;
    }

    // gửi event đến Bloc
    authBloc.add(LoginEvent(phone: phone, password: pass));
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          // có thể show loading indicator (hoặc overlay)
        } else if (state is AuthSuccess) {
          showSnack("Đăng nhập thành công");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BasePage()),
          );
        } else if (state is AuthFailure) {
          showSnack("Đăng nhập thất bại: ${state.message}");
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) {
          return previous != current;
        },
        builder: (BuildContext context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return AuthPage(
            onPhoneChanged: onPhoneChanged,
            onLogin: handleSubmit,
            isPhoneValid: isPhoneValid,
            phoneController: phoneController,
            passwordController: passwordController,
          );
        },
      ),
    );
  }
}
