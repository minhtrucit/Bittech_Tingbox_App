import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ting_box/services/api_services.dart';
import 'package:ting_box/services/auth_services.dart';
import 'package:ting_box/services/order_service.dart';
import 'package:ting_box/services/product_api_services.dart';
import 'package:ting_box/services/websocket_service.dart';
import 'package:ting_box/ting_box.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await dotenv.load(fileName: ".env");
  final baseUrl = dotenv.get('API_BASE_URL');
  final apiService = ApiService.getInstance(baseUrl: baseUrl);
  final authService = AuthService.getInstance(api: apiService);
  final userRepository = UserRepository();
  final productApiService = ProductApiService(
    baseUrl: baseUrl,
    api: apiService,
  );
  final orderService = OrderService(api: apiService);
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString(UserRepository.keyToken);
  final refreshToken = prefs.getString(UserRepository.keyRefreshToken);
  final webSocketService = WebSocketService(url: dotenv.get('WEBSOCKET_BASE_URL'));

  // webSocketService.connect();
  if (accessToken != null && refreshToken != null) {
    apiService.setTokens(accessToken: accessToken, refreshToken: refreshToken);
    debugPrint('[main] Loaded tokens from SharedPreferences');
  } else {
    debugPrint('[main] No tokens found in SharedPreferences');
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create:
              (_) => AuthBloc(
                authService: authService,
                userRepository: userRepository,
              ),
        ),
        BlocProvider<ProductBloc>(
          create: (_) => ProductBloc(productApiService: productApiService),
        ),
        BlocProvider<OrderBloc>(
          create: (_) => OrderBloc(orderService: orderService, webSocketService: webSocketService),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
