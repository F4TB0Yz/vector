import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';

enum ToastType { success, error, warning, info }

void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  if (!context.mounted) return;

  Color backgroundColor;
  Color textColor = Colors.white;

  switch (type) {
    case ToastType.success:
      backgroundColor = AppColors.primary;
      textColor = Colors.black;
      break;
    case ToastType.error:
      backgroundColor = Colors.red;
      break;
    case ToastType.warning:
      backgroundColor = const Color(0xFF00E5FF); // Neon Cyan
      textColor = Colors.black;
      break;
    case ToastType.info:
      backgroundColor = const Color(0xBF000000);
      break;
  }

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      Future.delayed(duration, () {
        if (context.mounted &&
            Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            ),
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
        ),
      );
    },
  );
}
