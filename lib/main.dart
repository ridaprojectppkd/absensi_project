import 'package:absensi_project/routes/app_routes.dart';
import 'package:absensi_project/screens/auth/login_screen.dart';
import 'package:absensi_project/screens/auth/register_screen.dart';
import 'package:absensi_project/screens/main_bottom_navigator_bar.dart';
import 'package:absensi_project/screens/forgot_password.dart.dart';
import 'package:absensi_project/screens/reset_password_screen.dart';
import 'package:absensi_project/screens/splashsceen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
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
        AppRoutes.ForgotPasswordEmail: (context) =>
            const ForgotPasswordScreen(),
        AppRoutes.resetPasswordWithOtp: (context) {
          final String email =
              ModalRoute.of(context)?.settings.arguments as String;
          return ResetPasswordWithOtpScreen(email: email);
        },
        // AppRoutes.attendanceList: (context) => AttendanceListScreen(),
        // AppRoutes.report: (context) => const PersonReportScreen(),
        // AppRoutes.profile: (context) => const ProfileScreen(),
      },

      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
