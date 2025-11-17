import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notification_flutter_client/common/theme.dart';
import 'package:notification_flutter_client/pages/AuthPage/auth.dart';
import 'package:notification_flutter_client/pages/HomePage/ui/home_page.dart';
import 'package:notification_flutter_client/services/auth_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      useInheritedMediaQuery: true,
      splitScreenMode: true,
      builder: (_, _) {
        return MaterialApp(
          title: 'BitTech Ting Box',
          theme: ThemeConfig.defaultLight,
          home: FutureBuilder<bool>(
            future: AuthService.isLoggedIn(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return snapshot.data! ? const HomePage() : const Auth();
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
