// import 'package:flutter/material.dart';

// class ThemeProvider extends ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.light; // Default theme is light

//   ThemeMode get themeMode => _themeMode;

//   void toggleTheme(bool isDarkMode) {
//     _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
//     notifyListeners(); // Notify all listeners about the theme change
//   }

//   // Define your light theme
//   static ThemeData lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primaryColor: AppColors.primaryy, // Sesuaikan dengan warna primary Anda
//     colorScheme: const ColorScheme.light(
//       primary: AppColors.primaryy,
//       onPrimary: Colors.white,
//       secondary: Colors.blueAccent,
//       onSecondary: Colors.white,
//       background: AppColors.background, // Warna background untuk mode terang
//       onBackground: AppColors.textDark, // Warna teks utama untuk mode terang
//       surface: Colors.white, // Warna permukaan (misal Card, Dialog)
//       onSurface: AppColors.textLight, // Warna teks di permukaan
//       error: AppColors.error,
//       onError: Colors.white,
//     ),
//     cardColor: Colors.white, // Warna card untuk mode terang
//     dividerColor: AppColors.border, // Warna divider untuk mode terang
//     // Tambahkan properti tema lainnya sesuai kebutuhan
//   );

//   // Define your dark theme
//   static ThemeData darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primaryColor:
//         Colors.deepPurple, // Warna primary yang berbeda untuk dark mode
//     colorScheme: const ColorScheme.dark(
//       primary: Colors.deepPurple, // Contoh warna primary dark mode
//       onPrimary: Colors.white,
//       secondary: Colors.tealAccent,
//       onSecondary: Colors.black,
//       background: Color(0xFF121212), // Warna background gelap
//       onBackground: Colors.white, // Warna teks utama untuk mode gelap
//       surface: Color(0xFF1E1E1E), // Warna permukaan gelap
//       onSurface: Colors.grey, // Warna teks di permukaan gelap
//       error: Colors.redAccent,
//       onError: Colors.white,
//     ),
//     cardColor: const Color(0xFF1E1E1E), // Warna card untuk mode gelap
//     dividerColor: Colors.grey.shade700, // Warna divider untuk mode gelap
//     // Tambahkan properti tema lainnya sesuai kebutuhan
//   );
// }

// // Pastikan AppColors didefinisikan atau ganti dengan nilai warna langsung
// class AppColors {
//   static const Color primaryy = Color(
//     0xFF4CAF50,
//   ); // Contoh warna primary (hijau)
//   static const Color background = Color(
//     0xFFF5F5F5,
//   ); // Contoh warna background terang
//   static const Color textDark = Color(0xFF333333); // Contoh warna teks gelap
//   static const Color textLight = Color(0xFF666666); // Contoh warna teks terang
//   static const Color error = Color(0xFFD32F2F); // Contoh warna error
//   static const Color border = Color(0xFFE0E0E0); // Contoh warna border
// }
