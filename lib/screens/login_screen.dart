import 'package:flutter/material.dart';
import '../navigation/role_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'customer/product_list_screen.dart';

enum AuthTab { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final identifierController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final authService = AuthService();

  AuthTab activeTab = AuthTab.signIn;
  String message = '';
  bool isLoading = false;

  Future<void> submit() async {
    setState(() => message = '');

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (activeTab == AuthTab.signIn) {
        final role = await authService.login(
          identifier: identifierController.text,
          password: passwordController.text,
        );
        if (!mounted) return;
        RoleRouter.navigateToRole(context, role);
      } else {
        final role = await authService.register(
          email: emailController.text,
          password: passwordController.text,
          phone: phoneController.text,
        );
        if (!mounted) return;
        RoleRouter.navigateToRole(context, role);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => message = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => message = 'Invalid email or password.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> forgotPassword() async {
    setState(() => message = '');

    final identifier = activeTab == AuthTab.signIn
        ? identifierController.text
        : emailController.text;

    if (identifier.trim().isEmpty) {
      setState(() => message = 'Please fill in all required fields.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.sendPasswordReset(identifier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => message = e.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void continueAsGuest() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );
  }

  void _switchTab(AuthTab tab) {
    setState(() {
      activeTab = tab;
      message = '';
    });
  }

  @override
  void dispose() {
    identifierController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = activeTab == AuthTab.signIn;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeroHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthTabs(
                        activeTab: activeTab,
                        onChanged: _switchTab,
                      ),
                      const SizedBox(height: 28),
                      if (isSignIn) ...[
                        _LabeledField(
                          label: 'EMAIL OR PHONE',
                          controller: identifierController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateIdentifier,
                          enabled: !isLoading,
                        ),
                      ] else ...[
                        _LabeledField(
                          label: 'EMAIL',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Please fill in all required fields.';
                            }
                            if (!Validators.isEmail(value!.trim())) {
                              return 'Please enter a valid email or phone number.';
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),
                        _LabeledField(
                          label: 'PHONE (OPTIONAL)',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return null;
                            if (!Validators.isPhone(trimmed)) {
                              return 'Please enter a valid email or phone number.';
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'MẬT KHẨU',
                        controller: passwordController,
                        obscureText: true,
                        validator: Validators.validatePassword,
                        enabled: !isLoading,
                      ),
                      if (!isSignIn) ...[
                        const SizedBox(height: 20),
                        _LabeledField(
                          label: 'CONFIRM PASSWORD',
                          controller: confirmPasswordController,
                          obscureText: true,
                          validator: (value) => Validators.validateConfirmPassword(
                            passwordController.text,
                            value,
                          ),
                          enabled: !isLoading,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kBackground,
                                  ),
                                )
                              : Text(isSignIn ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ'),
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _OrDivider(),
                      const SizedBox(height: 24),
                      _GoogleButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Google sign-in coming soon'),
                                  ),
                                );
                              },
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : forgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: kMuted,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : continueAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'TIẾP TỤC VỚI TƯ CÁCH KHÁCH →',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/hero_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  kBackground.withValues(alpha: 0.55),
                  kBackground,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RG/VN',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: kNeon,
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'TACTICAL ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'EXCELLENCE',
                        style: TextStyle(color: kNeon),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "VIETNAM'S PREMIER AIRSOFT ARMORY",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.activeTab,
    required this.onChanged,
  });

  final AuthTab activeTab;
  final ValueChanged<AuthTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Sign In',
            isActive: activeTab == AuthTab.signIn,
            onTap: () => onChanged(AuthTab.signIn),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: 'Sign Up',
            isActive: activeTab == AuthTab.signUp,
            onTap: () => onChanged(AuthTab.signUp),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: isActive ? kNeon : const Color(0xFF161C26),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? kBackground : kMuted,
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1.2,
            color: kMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            isDense: true,
            errorStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: kMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: kSurface,
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'TIẾP TỤC VỚI GOOGLE',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
