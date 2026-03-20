import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/config_model.dart';
import '../app_colors.dart';

class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final SubscriptionPlan plan;
  final int roleId;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.plan,
    this.roleId = 0,
  });

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items = [];

    switch (plan) {
      case SubscriptionPlan.basic:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_alt),
            label: "Hồ sơ",
          ),
        ];
        break;
      case SubscriptionPlan.fnb:
        if (roleId == 6) {
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.table_restaurant_outlined),
              activeIcon: Icon(Icons.table_restaurant),
              label: 'Bàn',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Đơn hàng',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ];
        } else {
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.table_restaurant_outlined),
              activeIcon: Icon(Icons.table_restaurant),
              label: 'Bàn',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Đơn hàng',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ];
        }
        break;
      case SubscriptionPlan.admin:
      case SubscriptionPlan.premium:
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Sản phẩm',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ];
        break;
    }

    return BottomNavigationBar(
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      items: items,
    );
  }
}
