import 'package:flutter/material.dart';
import 'admin/admin_home_screen.dart';

/// Entry-point wrapper used by HomeScreen's hidden 10-tap Easter-egg.
/// Call [AdminPanelScreen.openIfAuthorized] to navigate to the admin area.
class AdminPanelScreen {
  AdminPanelScreen._();

  static void openIfAuthorized(BuildContext context) {
    // TODO: add role-based auth check before pushing if needed.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
    );
  }
}
