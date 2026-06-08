import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/customer/product_list_screen.dart';
import '../screens/staff/staff_home_screen.dart';

class RoleRouter {
  static Widget screenForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.staff:
        return const StaffHomeScreen();
      case UserRole.customer:
        return const ProductListScreen();
    }
  }

  static void navigateToRole(BuildContext context, UserRole role) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screenForRole(role)),
      (route) => false,
    );
  }
}
