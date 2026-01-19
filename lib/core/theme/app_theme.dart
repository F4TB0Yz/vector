import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    final colorScheme = ColorScheme.dark(
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
