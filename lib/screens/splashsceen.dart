import 'dart:async';

import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/constants/app_style.dart';
import 'package:absensi_project/services/api_services.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Wait for the splash screen animation to play
    await Future.delayed(const Duration(seconds: 3));

    // Initialize ApiService to load the token from SharedPreferences
    // This is crucial to ensure the token is available before checking login status
    await ApiService.init();

    // Check if a token exists in ApiService (which means a user is logged in)
    final isLoggedIn =
        ApiService.getToken() !=
        null; // Assuming ApiService has a getter for token

    final nextRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;

    if (!mounted) return;

    // Navigate to the appropriate route
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Image(
                image: AssetImage('assets/images/logo.png'),
                width: 90,
                height: 90,
              ),
              SizedBox(height: 20),
              Text('AbsenSee', style: AppTextStyles.heading),
              SizedBox(height: 10),
              Text(
                'Selamat Datang!',
                textAlign: TextAlign.center,
                style: AppTextStyles.normal,
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
