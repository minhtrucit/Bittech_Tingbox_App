import 'package:flutter/material.dart';

import '../../../common/components/app_scaffold.dart';
import '../../../services/auth_services.dart';
import '../../AuthPage/auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void handleLogout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Auth()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => handleLogout(context),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
