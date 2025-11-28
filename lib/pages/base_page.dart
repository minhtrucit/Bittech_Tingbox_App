import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/ting_box.dart';

import 'ConfigPage/bloc/config_bloc.dart';
import 'ConfigPage/bloc/config_event.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final productBloc = BlocProvider.of<ProductBloc>(context);
    productBloc.add(GetProductsEvent());

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(UserRepository.keyUserId);

    if (userId != null && mounted) {
      final userProfileBloc = BlocProvider.of<UserProfileBloc>(context);
      userProfileBloc.add(GetUserEvent(userId: userId));
      context.read<ConfigBloc>().add(GetConfigEvent(userId: userId));
    }
  }

  final _pages = const [
    HomePage(),
    OrdersListPage(),
    HomePage(), // Placeholder for center button if needed, or just use index mapping
    ProductsListPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasSafeArea: false,
      backgroundColor: AppColors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _pages[_selectedIndex]),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
              ),
              child: AppNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanProductPage()),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
