import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/services/print_service.dart';
import 'package:ting_box/ting_box.dart';

import 'ConfigPage/bloc/config_bloc.dart';
import 'ConfigPage/bloc/config_event.dart';
import 'ConfigPage/bloc/config_state.dart';
import 'TableManagementPage/table_management_page.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;
  SubscriptionPlan _currentPlan = SubscriptionPlan.basic;
  int _roleId = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(UserRepository.keyUserId);
    final user = await UserRepository.getUser();
    if (mounted) {
      setState(() {
        _roleId = user?.roleId ?? 0;
        if (_roleId == 1) {
          _currentPlan = SubscriptionPlan.admin;
        } else if (_roleId == 2) {
          _currentPlan = SubscriptionPlan.premium;
        } else if (_roleId == 5 || _roleId == 6) {
          _currentPlan = SubscriptionPlan.fnb;
        } else {
          _currentPlan = SubscriptionPlan.basic;
        }
      });
    }

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

  List<Widget> get _pages {
    switch (_currentPlan) {
      case SubscriptionPlan.basic:
        return [const HomePage(), const UserProfilePage()];
      case SubscriptionPlan.fnb:
        if (_roleId == 6) {
          return [
            const TableManagementPage(),
            OrdersListPage(isVisible: _selectedIndex == 1),
            const UserProfilePage(),
          ];
        }
        return [
          const HomePage(),
          const TableManagementPage(),
          OrdersListPage(isVisible: _selectedIndex == 2),
          const UserProfilePage(),
        ];
      case SubscriptionPlan.admin:
      case SubscriptionPlan.premium:
        return [
          const HomePage(),
          OrdersListPage(isVisible: _selectedIndex == 1),
          const ProductsListPage(),
          const UserProfilePage(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is ConfigLoaded && state.config.id != null) {
          final prefix = dotenv.get('AGENT_ID_PREFIX');
          PrintService().init(
            agentId: '$prefix${state.config.id}',
            apiKey: state.config.sepayApiKey,
          );

          final now = DateTime.now();
          context.read<StatisticsBloc>().add(
            GetStatisticsEvent(
              startDate: _formatDate(now),
              endDate: _formatDate(now),
              configId: state.config.id!,
            ),
          );
          setState(() {
            if (_selectedIndex >= _pages.length) {
              _selectedIndex = 0;
            }
            _isLoading = false;
          });
          if (_currentPlan != SubscriptionPlan.basic) {
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
                          plan: _currentPlan,
                          roleId: _roleId,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
