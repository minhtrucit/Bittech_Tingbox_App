import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/AuthPage/auth.dart';

import 'package:ting_box/pages/base_page.dart';
import 'package:ting_box/services/auth_services.dart';

import 'common/theme.dart';

void main() async{
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await dotenv.load(fileName: '.env');
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

              return snapshot.data! ? const BasePage() : const Auth();
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
