import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import 'providers/auth_provider.dart';

/// Email sign-in / sign-up screen with email, password, confirm password.
/// Toggles between Login and Sign Up modes.
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _ready = false;
  bool _autoValidate = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Defer heavy content by one frame so the route slide animation
    // plays on a lightweight shell first — eliminates first-open jank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _autoValidate = true;
      _errorMessage = null; // Clear previous errors
    });
    
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(emailAuthControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      await controller.signUp(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }

    // Check for errors in the state after the operation
    final authState = ref.read(emailAuthControllerProvider);
    if (authState.hasError && mounted) {
      final error = authState.error;
      
      // Extract clean error message (remove any exception prefixes)
      String errorMessage = error.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      // If sign-up fails because account exists, suggest signing in instead
      if (_isSignUp && errorMessage.contains('already exists')) {
        setState(() {
          _isSignUp = false;
          _errorMessage = 'This email is already registered. Please sign in instead.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(emailAuthControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _ready
              ? CustomScrollView(
                  key: const ValueKey('content'),
                  physics: isLoading
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildForm(context, isLoading),
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('placeholder')),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.mode_of_travel_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          const Text(
            'TravelBuddy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSpacing = screenHeight * 0.03;
    final fieldSpacing = screenHeight * 0.018;
    final buttonSpacing = screenHeight * 0.03;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topSpacing),
            Text(
              _isSignUp ? 'Create Account' : 'Welcome Back',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSignUp
                  ? 'Sign up to start planning trips'
                  : 'Log in to continue your adventures',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: buttonSpacing),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.email,
            ),
            SizedBox(height: fieldSpacing),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: _isSignUp
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: Validators.password,
              onChanged: _isSignUp ? (_) => setState(() {}) : null,
            ),

            // Error message display
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Password requirements (sign-up only)
            if (_isSignUp) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequirement(
                      'At least 8 characters',
                      _passwordController.text.length >= 8,
                    ),
                    _buildRequirement(
                      'One uppercase letter',
                      _passwordController.text.contains(RegExp(r'[A-Z]')),
                    ),
                    _buildRequirement(
                      'One lowercase letter',
                      _passwordController.text.contains(RegExp(r'[a-z]')),
                    ),
                    _buildRequirement(
                      'One number',
                      _passwordController.text.contains(RegExp(r'[0-9]')),
                    ),
                    _buildRequirement(
                      'One special character (!@#\$%^&*)',
                      _passwordController.text.contains(
                        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Confirm password (sign-up only)
            if (_isSignUp) ...[
              SizedBox(height: fieldSpacing),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordController.text),
              ),
            ],

            SizedBox(height: buttonSpacing),

            // Submit button
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.6,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Create Account' : 'Log In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const Spacer(),

            // Toggle login / sign-up
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account?'
                        : "Don't have an account?",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null; // Clear error when switching modes
                    }),
                    child: Text(
                      _isSignUp ? 'Log In' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
