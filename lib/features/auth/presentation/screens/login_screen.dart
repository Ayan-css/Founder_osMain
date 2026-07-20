import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../main.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      context.showSnackBar('Please enter email and password', isError: true);
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);

    if (_isSignUp) {
      final success = await authNotifier.signUp(email, password);
      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Check Your Email'),
            content: const Text(
                'Your account has been created successfully!\n\n'
                'Please check your email inbox and click the verification link to verify your account before signing in.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isSignUp = false);
                },
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } else {
      final success = await authNotifier.signInWithEmail(email, password);
      if (success && mounted) {
        context.go(RouteNames.dashboard);
      }
    }
  }

  Future<void> _loginWithMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      context.showSnackBar('Please enter your email', isError: true);
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).signInWithMagicLink(email);
    if (success && mounted) {
      context.showSuccess('Magic link sent! Check your email.');
    }
  }

  Future<void> _skipLogin() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isGuest', true);
    ref.read(authNotifierProvider.notifier).setGuestMode(true);
    if (mounted) context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);

    // Show error if exists
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        context.showSnackBar(next.error!, isError: true);
      }
      if (next.hasAccess && prev?.hasAccess != true) {
        context.go(RouteNames.dashboard);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'RCM OS',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Agency Operating System',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Toggle sign up / sign in
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? 'Already have an account? Sign In' : 'No account? Sign Up',
                            style: TextStyle(color: colors.primary, fontSize: 13),
                          ),
                        ),
                        if (!_isSignUp)
                          TextButton(
                            onPressed: () async {
                              final email = _emailController.text.trim();
                              if (email.isEmpty) {
                                context.showSnackBar('Enter your email above first', isError: true);
                                return;
                              }
                              final success = await ref.read(authNotifierProvider.notifier).resetPassword(email);
                              if (mounted) {
                                if (success) {
                                  context.showSuccess('Password reset email sent! Check your inbox.');
                                } else {
                                  final err = ref.read(authNotifierProvider).error;
                                  context.showSnackBar(err ?? 'Failed to send reset email', isError: true);
                                }
                              }
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: colors.primary, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sign In / Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: authState.isLoading ? null : _loginWithEmail,
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Magic Link
                    if (!_isSignUp)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: authState.isLoading ? null : _loginWithMagicLink,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Sign in with Magic Link'),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.outline.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.outline.withValues(alpha: 0.2))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skip - Offline mode
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: _skipLogin,
                        child: const Text('Continue Offline →'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
