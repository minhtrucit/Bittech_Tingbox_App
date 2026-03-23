import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/StartingBalancePage/bloc/cash_book_bloc.dart';
import 'package:ting_box/pages/SalesPage/bloc/cart_bloc.dart';

import 'package:ting_box/services/api_services.dart';
import 'package:ting_box/services/auth_services.dart';
import 'package:ting_box/services/config_service.dart';
import 'package:ting_box/services/ocr_service.dart';
import 'package:ting_box/services/order_service.dart';
import 'package:ting_box/services/product_api_services.dart';
import 'package:ting_box/ting_box.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/websocket_manager.dart';
import 'services/user_services.dart';
import 'services/sse_services.dart';
import 'services/ocr_correction_service.dart';
import 'pages/ProductPage/bloc/ocr_correction_bloc.dart';
import 'utils/audio_manager.dart';
import 'services/table_service.dart';
import 'pages/TableManagementPage/bloc/table_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await dotenv.load(fileName: ".env");
  final baseUrl = dotenv.get('API_BASE_URL');
  final detectUrl = dotenv.get('API_DETECT_URL');
  final apiService = ApiService.getInstance(baseUrl: baseUrl);
  final authService = AuthService.getInstance(api: apiService);
  final userRepository = UserRepository();
  final productApiService = ProductApiService(
    baseUrl: detectUrl,
    api: apiService,
  );
  final userService = UserService(api: apiService);
  final orderService = OrderService(api: apiService);
  final configService = ConfigService(api: apiService);
  final ocrService = OcrService.getInstance();
  final ocrCorrectionService = OcrCorrectionService();
  final statisticServices = StatisticServices(api: apiService);
  final tableService = TableService(api: apiService);
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString(UserRepository.keyToken);
  final refreshToken = prefs.getString(UserRepository.keyRefreshToken);
  final webSocketManager = WebSocketManager();

  // Initialize Audio Manager
  AudioManager().init();

  webSocketManager.connect(dotenv.get('WEBSOCKET_BASE_URL'));
  if (accessToken != null && refreshToken != null) {
    apiService.setTokens(accessToken: accessToken, refreshToken: refreshToken);
    SSEService.instance.connect();
    debugPrint('[main] Loaded tokens and connecting SSE');
  } else {
    debugPrint('[main] No tokens found in SharedPreferences');
  }

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>.value(value: apiService),
        RepositoryProvider<TableService>.value(value: tableService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create:
                (_) => AuthBloc(
                  authService: authService,
                  userRepository: userRepository,
                ),
          ),
          BlocProvider<ProductBloc>(
            create:
                (_) => ProductBloc(
                  productApiService: productApiService,
                  ocrService: ocrService,
                ),
          ),
          BlocProvider<OrderBloc>(
            create: (_) => OrderBloc(orderService: orderService),
          ),
          BlocProvider<UserProfileBloc>(
            create: (_) => UserProfileBloc(userService: userService),
          ),
          BlocProvider<ConfigBloc>(
            create: (_) => ConfigBloc(configService: configService),
          ),
          BlocProvider<StatisticsBloc>(
            create: (_) => StatisticsBloc(statisticServices: statisticServices),
          ),
          BlocProvider<CashBookBloc>(
            create: (_) => CashBookBloc(statisticServices: statisticServices),
          ),
          BlocProvider<CartBloc>(create: (_) => CartBloc()),
          BlocProvider<OcrCorrectionBloc>(
            create:
                (_) =>
                    OcrCorrectionBloc(correctionService: ocrCorrectionService),
          ),
          BlocProvider<TableBloc>(
            create: (_) => TableBloc(tableService: tableService),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BitTech Ting Box',
          theme: ThemeConfig.defaultLight,
          locale: const Locale('vi', 'VN'),
          supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child, // Use the stable child here
          debugShowCheckedModeBanner: false,
        );
      },
      child: const InitializerPage(), // Define the stable child here
    );
  }
}

class InitializerPage extends StatefulWidget {
  const InitializerPage({super.key});

  @override
  State<InitializerPage> createState() => _InitializerPageState();
}

class _InitializerPageState extends State<InitializerPage> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = UserRepository.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (snapshot.data == true) {
          return const BasePage();
        }

        return const Auth();
      },
    );
  }
}
