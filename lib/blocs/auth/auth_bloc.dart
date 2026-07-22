import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  StreamSubscription<String?>? _authSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<_AuthInternalStatusChanged>(_onInternalStatusChanged);
  }

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (userId) => add(_AuthInternalStatusChanged(userId)),
    );
  }

  void _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    _authRepository.signOut();
  }

  // Internal event to handle stream updates
  Future<void> _onInternalStatusChanged(
    _AuthInternalStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.userId != null) {
      final role = await _userRepository.getUserRole(event.userId!);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userId: event.userId,
        role: role,
        isEmailVerified: _authRepository.isEmailVerified,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        userId: null,
        role: null,
        isEmailVerified: false,
      ));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

class _AuthInternalStatusChanged extends AuthEvent {
  final String? userId;
  const _AuthInternalStatusChanged(this.userId);

  @override
  List<Object?> get props => [userId];
}
