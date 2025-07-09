import 'package:absensi_project/routes/app_routes.dart';
import 'package:absensi_project/screens/attendance/request_screen.dart';
import 'package:absensi_project/screens/auth/login_screen.dart';
import 'package:absensi_project/screens/auth/register_screen.dart';
import 'package:absensi_project/screens/buttom_navigator_bar.dart';
import 'package:absensi_project/screens/forgot_password.dart.dart';
import 'package:absensi_project/screens/reset_password_screen.dart';
import 'package:absensi_project/screens/splashsceen.dart';
import 'package:absensi_project/screens/otp_verification_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.initial,
      routes: {
        AppRoutes.initial: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.main: (context) => MainBottomNavigationBar(),
        AppRoutes.request: (context) => RequestScreen(),
        AppRoutes.otpVerification: (context) => const OtpVerificationScreen(email: '',),
        AppRoutes.ForgotPasswordEmail: (context) => const ForgotPasswordEmailScreen(),
        AppRoutes.resetPassword: (context) => ResetPasswordScreen(email: '', otp: '',)// Pass email and OTP as needed
        // AppRoutes.attendanceList: (context) => AttendanceListScreen(),
        // AppRoutes.report: (context) => const PersonReportScreen(),
        // AppRoutes.profile: (context) => const ProfileScreen(),
      },

      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
