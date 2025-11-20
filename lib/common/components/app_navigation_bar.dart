import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
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
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.money_dollar_circle),
          label: "Quỹ",
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.doc_text),
          label: "Chi phí",
        ),
        BottomNavigationBarItem(
          icon: SizedBox(width: 40),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.cart_fill),
          label: "Bán hàng",
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_alt),
          label: "Hồ sơ",
        ),
      ],
    );
  }
}
