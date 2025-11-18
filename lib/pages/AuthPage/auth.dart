import 'package:flutter/material.dart';
import 'package:ting_box/pages/AuthPage/ui/auth_page.dart';

import '../../services/auth_services.dart';
import '../base_page.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPhoneValid = true;

  void onPhoneChanged(String value) {
    setState(() {
      isPhoneValid = isValidPhone(value);
    });
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^[0-9]{6,15}$');
    return regex.hasMatch(phone);
  }


  void handleSubmit() async {
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      showSnack("Vui lòng nhập đủ thông tin");
      return;
    }

    final result = await AuthService.loginOrRegister(phone, pass);

    switch (result) {
      case "login_ok":
        showSnack("Đăng nhập thành công");
        break;
      case "registered":
        showSnack("Số điện thoại chưa có, đã tạo tài khoản mới!");
        break;
      case "wrong_password":
        showSnack("Sai mật khẩu!");
        return;
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BasePage()),
      );
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      onPhoneChanged: onPhoneChanged,
      onLogin: handleSubmit,
      isPhoneValid: isPhoneValid,
      phoneController: phoneController,
      passwordController: passwordController,
    );
  }
}
