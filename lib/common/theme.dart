import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract class ThemeConfig {
  static ThemeData defaultLight = variant(
    primaryColor: AppColors.primaryBlue,
    secondaryColor: AppColors.secondaryColor,
  );

  static ThemeData variant({
    required Color primaryColor,
    required Color secondaryColor,
    bool darkMode = false,
  }) {
    return ThemeData(
      fontFamily: 'Montserrat',
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionHandleColor: primaryColor,
      ),
      scaffoldBackgroundColor: AppColors.white,
      brightness: darkMode ? Brightness.dark : Brightness.light,
    );
  }
}
