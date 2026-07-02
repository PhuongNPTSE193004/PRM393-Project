import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../navigation/role_router.dart';
import '../../models/user_role.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final authService = AuthService();
  Timer? _timer;
  bool _isChecking = false;
  bool _canResend = true;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String _message = '';
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _isVerified = authService.isEmailVerified;
    if (_isVerified) {
      _navigateToHome();
    } else {
      // Check status periodically every 3 seconds
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerificationStatus());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus({bool manual = false}) async {
    if (_isChecking || _isVerified) return;

    setState(() {
      _isChecking = true;
      _message = '';
    });

    try {
      await authService.reloadUser();
      final verified = authService.isEmailVerified;
      if (verified) {
        _timer?.cancel();
        setState(() {
          _isVerified = true;
          _message = 'EMAIL VERIFIED SUCCESSFULLY. ROUTING...';
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _navigateToHome();
        }
      } else if (manual) {
        setState(() {
          _message = 'EMAIL NOT VERIFIED YET. PLEASE CHECK YOUR INBOX.';
        });
      }
    } catch (e) {
      if (manual) {
        setState(() {
          _message = 'ERROR CHECKING STATUS: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _navigateToHome() async {
    try {
      final role = await authService.getCurrentUserRole();
      if (role != null && mounted) {
        RoleRouter.navigateToRole(context, role);
      }
    } catch (_) {
      // Fallback
      if (mounted) {
        RoleRouter.navigateToRole(context, UserRole.customer);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
      _message = 'VERIFICATION EMAIL SENT.';
    });

    try {
      await authService.sendEmailVerification();
    } catch (e) {
      setState(() {
        _message = 'FAILED TO SEND VERIFICATION EMAIL. PLEASE TRY AGAIN.';
      });
    }

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
          _cooldownSeconds = 0;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _logoutAndBack() async {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    try {
      await authService.logout();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Pulse/Radar Indicator for Tactical Feel
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PulseCircle(isVerified: _isVerified),
                      Icon(
                        _isVerified ? Icons.verified_user : Icons.mark_email_unread_outlined,
                        color: _isVerified ? kNeon : kMuted,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'EMAIL VERIFICATION REQUIRED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kNeon,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'A secure verification link has been sent to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Please click the link in the email to verify and complete your registration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: kMuted,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (_message.isNotEmpty) ...[
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: _isVerified ? kNeon : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Manual Check Button
              OutlinedButton(
                onPressed: _isChecking ? null : () => _checkVerificationStatus(manual: true),
                style: OutlinedButton.styleFrom(
                  backgroundColor: kSurface,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CHECK STATUS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              // Resend Email Button
              OutlinedButton(
                onPressed: _canResend ? _resendVerificationEmail : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: _canResend ? kNeon : kMuted,
                  side: BorderSide(color: _canResend ? kNeon.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _canResend ? 'RESEND LINK' : 'RESEND IN ${_cooldownSeconds}S',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back to Login Button
              TextButton(
                onPressed: _logoutAndBack,
                style: TextButton.styleFrom(
                  foregroundColor: kMuted,
                ),
                child: const Text(
                  '← BACK TO LOGIN',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  final bool isVerified;

  const _PulseCircle({required this.isVerified});

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVerified) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kNeon.withValues(alpha: 0.1),
          border: Border.all(color: kNeon, width: 2),
        ),
      );
    }

    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kSurface,
          border: Border.all(color: kMuted.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
    );
  }
}
