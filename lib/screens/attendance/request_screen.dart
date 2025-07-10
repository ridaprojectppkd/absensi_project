import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/models/app_model.dart';
import 'package:absensi_project/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../../widgets/custom_date_input_field.dart'; // Your CustomDateInputField
import '../../widgets/custom_input_field.dart'; // Your CustomInputField
import '../../widgets/primary_button.dart'; // Your PrimaryButton

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  DateTime? _selectedDate;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // No location-related initialization needed
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textDark, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    // Basic validation
    if (_selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }
    if (_reasonController.text.isEmpty) {
      _showSnackBar('Please enter a reason for the request.');
      return;
    }

    setState(() {
      _isLoading = true; // Set loading to true
    });

    try {
      // Format the selected date to yyyy-MM-dd as required by the /izin API
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);

      // Call the dedicated submitIzinRequest method from ApiService
      final ApiResponse<Absence> response = await _apiService.submitIzinRequest(
        date: formattedDate, // Pass the formatted date as 'date'
        alasanIzin: _reasonController.text.trim(), // Only send the reason text
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSnackBar('Request submitted successfully!');
          Navigator.pop(context, true); // Pop with true to indicate success
        }
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showSnackBar('Failed to submit request: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: $e');
      }
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Request'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker using CustomDateInputField
            CustomDateInputField(
              labelText: 'Select Date',
              icon: Icons.calendar_today,
              selectedDate: _selectedDate,
              onTap: () => _selectDate(context),
              hintText: 'No date chosen', // Optional hint text
            ),
            const SizedBox(height: 20),

            // Reason Text Field using CustomInputField
            CustomInputField(
              controller: _reasonController,
              labelText:
                  'Reason for Request', // This becomes the floating label
              hintText:
                  'e.g., Annual leave, sick leave, personal matters', // This remains the hint text inside the field
              icon: Icons.edit_note,
              maxLines: 3, // Allow multiline input
              keyboardType:
                  TextInputType.multiline, // Set keyboard to multiline
              fillColor: AppColors.inputFill, // Match previous fillColor
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ), // Adjusted vertical padding
              customValidator: (value) {
                // Use customValidator for specific validation
                if (value == null || value.trim().isEmpty) {
                  return 'Reason cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Submit Button using PrimaryButton
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : PrimaryButton(
                    label: 'Submit Request',
                    onPressed: _submitRequest,
                  ),
          ],
        ),
      ),
    );
  }
}
