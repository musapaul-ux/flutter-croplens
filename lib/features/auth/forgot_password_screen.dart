import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/auth_repository.dart';

enum _Step { email, code, success }

/// Forgot Password flow — three steps in one screen:
///  1. Enter email -> request a 6-digit reset code
///  2. Enter the code + new password -> reset it
///  3. Success confirmation
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  bool _isLoading = false;

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authRepo = AuthRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authRepo.forgotPassword(_emailController.text.trim());
      setState(() {
        _isLoading = false;
        _step = _Step.code;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      _showError(e.message);
    }
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authRepo.resetPassword(
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      setState(() {
        _isLoading = false;
        _step = _Step.success;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      _showError(e.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Reset code is required';
    if (value.trim().length != 6) return 'Code must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Code must contain only numbers';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: switch (_step) {
            _Step.email => _buildEmailStep(context),
            _Step.code => _buildCodeStep(context),
            _Step.success => _buildSuccessStep(context),
          },
        ),
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _emailFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Forgot your password?', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              "Enter the email linked to your account and we'll send you a 6-digit reset code.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.email,
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Send Reset Code', isLoading: _isLoading, onPressed: _requestCode),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _resetFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Enter your reset code', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'We sent a 6-digit code to ${_emailController.text.trim()}. Enter it below along with your new password.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Reset Code',
              controller: _codeController,
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              validator: _validateCode,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'New Password',
              controller: _newPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _newPasswordController.text),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Reset Password', isLoading: _isLoading, onPressed: _submitReset),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _requestCode,
                child: const Text("Didn't get a code? Resend"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline, size: 44, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Password reset!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Your password has been updated. Please log in with your new password.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Back to Log In', onPressed: () => context.goNamed('login')),
          ),
        ],
      ),
    );
  }
}