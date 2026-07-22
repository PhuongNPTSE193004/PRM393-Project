import 'package:equatable/equatable.dart';
import '../../models/user_role.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? userId;
  final UserRole? role;
  final bool isEmailVerified;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.role,
    this.isEmailVerified = false,
    this.error,
  });

  @override
  List<Object?> get props => [status, userId, role, isEmailVerified, error];

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    UserRole? role,
    bool? isEmailVerified,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      error: error ?? this.error,
    );
  }
}
