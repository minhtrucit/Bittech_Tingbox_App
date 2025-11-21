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
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Đăng nhập thất bại',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Vui lòng nhập đầy đủ số điện thoại và mật khẩu!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          );
        },
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

          await Future.delayed(const Duration(milliseconds: 200));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BasePage()),
          );
        }

        if (state is AuthFailure) {
          debugPrint('[AuthListener] AuthFailure: ${state.message}');
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text(
                  'Đăng nhập thất bại',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            },
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
          if (_isLoadingOverlay) LoadingOverlay(),
        ],
      ),
    );
  }
}
