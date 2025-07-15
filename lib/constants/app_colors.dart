import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color (Blue) - Keep your existing primary
  static const Color primary = Color(0XFF00674F);

  // Backgrounds
  static const Color background = Color(0xFFF9FAFB); // Very light gray
  static const Color card = Color(0xFFFFFFFF); // White cards/containers
  static const Color inputFill = Color(
    0xFFF3F4F6,
  ); // Slightly darker than background

  // Text
  static const Color textDark = Color(0xFF1F2937); // Almost black
  static const Color textLight = Color(0xFF9CA3AF); // Muted gray
  static const Color placeholder = Color(0xFF6B7280); // Placeholder text

  // Borders & dividers
  static const Color border = Color(0xFFE5E7EB); // Soft gray

  // States
  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Added colors for attendance list design, mapping to your existing states
  static const Color accentGreen =
      AppColors.success; // Using existing success color
  static const Color accentRed = AppColors.error; // Using existing error color
  static const Color accentOrange =
      AppColors.warning; // Using existing warning color

  // Specific light background colors for the cards
  static const Color lightGreenBackground = Color(0xFFE8F5E9); // Lighter green
  static const Color lightRedBackground = Color(0xFFFFEBEE); // Lighter red
  static const Color lightOrangeBackground = Color(
    0xFFFFF3E0,
  ); // Lighter orange

  // NEW COLORS FROM THE IMAGE
  // Top Action Card Colors
  static const Color blueCard = Color(
    0xFF5B3AEE,
  ); // Matches the blue "Buildings" card
  static const Color tealCard = Color(
    0xFF00C8C8,
  ); // Matches the teal "Repair" card
  static const Color orangeCard = Color(
    0xFFFC8F2B,
  ); // Matches the orange "Maintain" card
  ////
  /////////////stats color and chart colors
  static const Color present = Color(0xFF81E7AF);
  static const Color absent= Color(0xFFF75A5A);
  static const Color total = Color(0xFFFFA955);

  // Operating Status Colors
  static const Color normalStatus = Color(0xFF1ABC9C); // Green for "Normal"
  static const Color offlineStatus = Color(0xFF95A5A6); // Grey for "Offline"
  static const Color failureStatus = Color(0xFFE74C3C); // Red for "Failure"
}
