import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/auth_repository.dart';

/// Screen 4 — Reset Password.
/// Enter New Password, Confirm Password. Shows success message after reset.
class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _success = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link is missing or invalid. Please request a new one.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authRepo.resetPassword(
        token: widget.token!,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      setState(() {
        _isLoading = false;
        _success = true;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
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
          child: _success ? _buildSuccessView(context) : _buildFormView(context),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Set a new password', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Choose a strong password you haven\'t used before.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
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
            PrimaryButton(label: 'Reset Password', isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
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
