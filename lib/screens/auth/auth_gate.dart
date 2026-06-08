import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../navigation/role_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBackground,
            body: Center(
              child: CircularProgressIndicator(color: kNeon),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<UserRole?>(
          future: authService.getCurrentUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: kBackground,
                body: Center(
                  child: CircularProgressIndicator(color: kNeon),
                ),
              );
            }

            final role = roleSnapshot.data;
            if (role == null) {
              return const LoginScreen();
            }

            return RoleRouter.screenForRole(role);
          },
        );
      },
    );
  }
}
