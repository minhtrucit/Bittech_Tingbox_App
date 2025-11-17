import 'package:flutter/material.dart';
import 'package:notification_flutter_client/common/theme.dart';
import 'package:notification_flutter_client/pages/AuthPage/auth_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeConfig.defaultLight,
      home: const AuthPage(),
    );
  }
}


