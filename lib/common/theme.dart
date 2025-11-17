import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_transition_builder.dart';

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
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CustomTransitionBuilder(),
          TargetPlatform.iOS: CustomTransitionBuilder(),
        },
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionHandleColor: primaryColor,
      ),
      brightness: darkMode ? Brightness.dark : Brightness.light,
    );
  }
}
