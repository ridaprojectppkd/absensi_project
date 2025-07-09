import 'package:absensi_project/screens/reset_password_screen.dart';

import 'package:absensi_project/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:absensi_project/models/app_model.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpVerified = false; // THIS IS THE KEY FLAG

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    // Prevent multiple clicks while loading
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOtpVerified = false; // Reset verification status before new attempt
    });

    final String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP.';
        _isLoading = false;
      });
      return;
    }

    final ApiResponse<void> response = await _apiService.verifyOtp(
      email: widget.email,
      otp: otp,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      // OTP VERIFICATION SUCCESSFUL!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'OTP verified successfully!')),
      );
      setState(() {
        _isOtpVerified = true; // Set the flag to true
      });
      // NO NAVIGATION HERE YET, JUST SHOW THE BUTTON
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to verify OTP. Please try again.';
        if (response.errors != null && response.errors!.isNotEmpty) {
          _errorMessage = response.errors!.values.first[0];
        }
      });
    }
  }

  // --- Resend OTP function (only for the TextButton below) ---
  Future<void> _resendOtp() async {
    // Disable resend if already loading or OTP is already verified
    if (_isLoading || _isOtpVerified) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ApiResponse<void> response = await _apiService.forgotPassword(
      email: widget.email,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'OTP resent successfully!')),
      );
      _otpController.clear(); // Clear input as new OTP is sent
      setState(() {
        _isOtpVerified = false; // Reset verified status as new OTP needs verification
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to resend OTP. Please try again.';
        if (response.errors != null && response.errors!.isNotEmpty) {
          _errorMessage = response.errors!.values.first[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'An OTP has been sent to ${widget.email}. Please enter it below to verify your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              onChanged: (_) {
                // If user changes OTP, invalidate current verification status
                if (_isOtpVerified) {
                  setState(() {
                    _isOtpVerified = false;
                  });
                }
              },
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 16),
            // The Resend OTP button is disabled if:
            // 1. A network request is in progress (_isLoading).
            // 2. The OTP has already been successfully verified (_isOtpVerified).
            TextButton(
              onPressed: (_isLoading || _isOtpVerified) ? null : _resendOtp,
              child: Text(
                'Resend OTP',
                style: TextStyle(color: Colors.blueAccent.withOpacity(
                  (_isLoading || _isOtpVerified) ? 0.5 : 1.0 // Visual feedback when disabled
                )),
              ),
            ),
            // --- THIS IS WHERE THE "NEXT" BUTTON APPEARS ---
            if (_isOtpVerified) // Only show this button if OTP verification was successful
              Column(
                children: [
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Reset Password Screen immediately
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordScreen(
                            email: widget.email,
                            otp: _otpController.text.trim(), // Pass the verified OTP
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.green, // Distinct color for clarity
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Next (Reset Password)',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}