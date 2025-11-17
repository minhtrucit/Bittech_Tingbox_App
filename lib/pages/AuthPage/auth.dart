import 'package:flutter/material.dart';
import 'package:notification_flutter_client/pages/AuthPage/ui/auth_page.dart';

import '../../services/auth_services.dart';
import '../HomePage/ui/home_page.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleLogin() async {
    if (phoneController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      await AuthService.login();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      onLogin: handleLogin,
      phoneController: phoneController,
      passwordController: passwordController,
    );
  }
}
