import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isPremium;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Home"),
        if (isPremium) ...[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            label: "Đơn hàng",
          ),
          BottomNavigationBarItem(icon: SizedBox(width: 40), label: ''),

          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cart_fill),
            label: "Sản phẩm",
          ),
        ],
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_alt),
          label: "Hồ sơ",
        ),
      ],
    );
  }
}
