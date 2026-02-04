import 'package:flutter/material.dart';

import 'package:vector/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'SpaceGrotesk',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
    );
  }
}
