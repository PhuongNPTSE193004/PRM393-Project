import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../navigation/role_router.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'verification_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.loading || state.status == AuthStatus.initial) {
          return const Scaffold(
            backgroundColor: kBackground,
            body: Center(
              child: CircularProgressIndicator(color: kNeon),
            ),
          );
        }

        if (state.status == AuthStatus.unauthenticated || state.userId == null) {
          return const LoginScreen();
        }

        // Save FCM token for logged in user (pseudo-code, ensure PushNotificationService can handle this)
        // PushNotificationService().saveUserFcmToken(state.userId); 

        if (!state.isEmailVerified) {
          // We might need to fetch the email from the repository if not in state
          return const VerificationScreen(email: ''); 
        }

        if (state.role == null) {
          return const LoginScreen();
        }

        return RoleRouter.screenForRole(state.role!);
      },
    );
  }
}
