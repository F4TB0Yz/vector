import 'package:flutter/material.dart';

class NavBarVisibilityNotification extends Notification {
  final bool isVisible;

  const NavBarVisibilityNotification(this.isVisible);
}

class ChangeTabNotification extends Notification {
  final int targetIndex;

  const ChangeTabNotification(this.targetIndex);
}
