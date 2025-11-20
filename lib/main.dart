import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/AuthPage/auth.dart';
import 'package:ting_box/pages/AuthPage/bloc/auth_bloc.dart';

import 'package:ting_box/pages/base_page.dart';
import 'package:ting_box/repositories/user_repository.dart';
import 'package:ting_box/services/api_services.dart';
import 'package:ting_box/services/auth_services.dart';

import 'common/theme.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final apiService = ApiService.getInstance(baseUrl: 'https://api-tingbox.bittechx.cloud' ?? '');
  final authService = AuthService.getInstance(api: apiService);
  final userRepository = UserRepository();
  runApp( BlocProvider(
    create: (_) => AuthBloc(authService: authService, userRepository: userRepository,),
    child: const MyApp(),
  ),);
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
            future: UserRepository.isLoggedIn(),
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
