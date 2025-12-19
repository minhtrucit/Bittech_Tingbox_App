import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/ting_box.dart';

import 'ConfigPage/bloc/config_bloc.dart';
import 'ConfigPage/bloc/config_event.dart';
import 'ConfigPage/bloc/config_state.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;
  ConfigModel? _configModel;
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(UserRepository.keyUserId);
    if (userId != null && mounted) {
      final userProfileBloc = BlocProvider.of<UserProfileBloc>(context);
      userProfileBloc.add(GetUserEvent(userId: userId));
      context.read<ConfigBloc>().add(GetConfigEvent(userId: userId));
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  List<Widget> get _pages => [
    const HomePage(),
    if (_isPremium) ...[
      OrdersListPage(isVisible: _selectedIndex == 1),
      const HomePage(), // Placeholder
      const ProductsListPage(),
    ],
    const UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is ConfigLoaded && state.config.id != null) {
          // Fetch statistics when config is loaded
          final now = DateTime.now();
          context.read<StatisticsBloc>().add(
            GetStatisticsEvent(
              startDate: _formatDate(now),
              endDate: _formatDate(now),
              configId: state.config.id!,
            ),
          );
          setState(() {
            _configModel = state.config;
            _isPremium = _configModel?.checkPremium() ?? false;
            // Ensure selected index is valid if items changed
            if (_selectedIndex >= _pages.length) {
              _selectedIndex = 0;
            }
            _isLoading = false;
          });
          if (_isPremium) {
            context.read<ProductBloc>().add(GetProductsEvent());
          }
        } else if (state is ConfigFailure) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child:
          _isLoading
              ? const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
              )
              : AppScaffold(
                hasSafeArea: false,
                backgroundColor: AppColors.white,
                body: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
                    ),

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
                          onTap:
                              (index) => setState(() => _selectedIndex = index),
                          isPremium: _isPremium,
                        ),
                      ),
                    ),
                    if (_isPremium)
                      Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanProductPage(),
                                ),
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
              ),
    );
  }
}
