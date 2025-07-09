import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/constants/app_style.dart';
import 'package:absensi_project/routes/app_routes.dart';
import 'package:absensi_project/services/api_services.dart';
import 'package:absensi_project/widgets/custom_input_field.dart';
import 'package:absensi_project/widgets/primary_button.dart';

import 'package:flutter/material.dart';

class ResetPasswordWithOtpScreen extends StatefulWidget {
  final String email; // Email passed from ForgotPasswordScreen

  const ResetPasswordWithOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordWithOtpScreen> createState() =>
      _ResetPasswordWithOtpScreenState();
}

class _ResetPasswordWithOtpScreenState
    extends State<ResetPasswordWithOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String otp = _otpController.text.trim();
      final String newPassword = _newPasswordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();

      // First, verify OTP (though the reset-password endpoint might handle this implicitly)
      // According to your API, the /reset-password endpoint takes email, otp, password, and password_confirmation
      // so we can directly call resetPassword.
      final response = await _apiService.resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showSnackBar(response.message);
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        _showSnackBar(errorMessage);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Enter OTP and New Password",
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 10),
              Text(
                "An OTP has been sent to ${widget.email}. Please enter it below along with your new password.",
                style: AppTextStyles.normal,
              ),
              const SizedBox(height: 30),
              CustomInputField(
                controller: TextEditingController(
                  text: widget.email,
                ), // Display email, not editable
                hintText: 'Email',
                labelText: 'Email Address',
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              CustomInputField(
                controller: _otpController,
                hintText: 'OTP',
                labelText: 'One-Time Password (OTP)',
                icon: Icons.vpn_key_outlined,
                keyboardType: TextInputType.number,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'OTP cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomInputField(
                controller: _newPasswordController,
                hintText: 'New Password',
                labelText: 'New Password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'New password cannot be empty';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomInputField(
                controller: _confirmPasswordController,
                hintText: 'Confirm New Password',
                labelText: 'Confirm New Password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm password cannot be empty';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : PrimaryButton(
                      label: 'Reset Password',
                      onPressed: _resetPassword,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}