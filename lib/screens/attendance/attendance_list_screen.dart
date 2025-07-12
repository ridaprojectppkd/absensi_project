import 'dart:async';

import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/models/app_model.dart';
import 'package:absensi_project/screens/buttom_navigator_bar.dart';
import 'package:absensi_project/services/api_services.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const AttendanceListScreen({super.key, required this.refreshNotifier});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Absence>>
  _attendanceFuture; // Changed to Future<List<Absence>>

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _fetchAndFilterAttendances();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      print(
        'AttendanceListScreen: Refresh signal received, refreshing list...',
      );
      _refreshList();
      widget.refreshNotifier.value = false;
    }
  }

  Future<List<Absence>> _fetchAndFilterAttendances() async {
    // Format the start and end dates for the API call
    final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
    final String endDate = DateFormat('yyyy-MM-dd').format(
      DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      ), // Last day of the month
    );

    try {
      final ApiResponse<List<Absence>> response = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      if (response.statusCode == 200 && response.data != null) {
        final List<Absence> fetchedAbsences = response.data!;
        // Sort by created_at date in descending order (latest first)
        fetchedAbsences.sort((a, b) {
          // Handle null createdAt dates: nulls come last
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null)
            return 1; // a is null, b is not, a comes after b
          if (b.createdAt == null)
            return -1; // b is null, a is not, b comes after a
          return b.createdAt!.compareTo(
            a.createdAt!,
          ); // Both are non-null, compare
        });
        return fetchedAbsences;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Error fetching and filtering attendance list: $e');
      // Show a SnackBar for the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: $e')),
        );
      }
      return []; // Return an empty list on error
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _attendanceFuture = _fetchAndFilterAttendances();
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateTime newSelectedMonth = DateTime(picked.year, picked.month, 1);
      if (newSelectedMonth.year != _selectedMonth.year ||
          newSelectedMonth.month != _selectedMonth.month) {
        setState(() {
          _selectedMonth = newSelectedMonth;
        });
        _refreshList();
      }
    }
  }

  String _calculateWorkingHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) {
      return '00:00:00';
    }

    DateTime endDateTime =
        checkOut ?? DateTime.now(); // Use current time if no checkout

    final Duration duration = endDateTime.difference(checkIn);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAttendanceTile(Absence absence) {
    Color barColor;
    Color statusPillColor;
    Color cardBackgroundColor = AppColors.background;
    Color timeTextColor;

    // Determine if it's a request type based on 'status' being 'izin'
    bool isRequestType =
        absence.status?.toLowerCase() == 'izin'; // Safely call toLowerCase

    if (isRequestType) {
      barColor = AppColors.accentOrange;
      statusPillColor = AppColors.accentOrange;
      cardBackgroundColor = AppColors.lightOrangeBackground;
      timeTextColor = Colors.black; // Not directly used for request types
    } else {
      // For regular check-in/out, determine status based on 'status' field
      if (absence.status?.toLowerCase() == 'late') {
        // Safely call toLowerCase
        barColor = AppColors.accentRed;
        statusPillColor = AppColors.accentRed;
        timeTextColor = AppColors.accentRed;
      } else {
        // Assuming 'masuk' or other non-late status is 'on time'
        barColor = AppColors.accentGreen;
        statusPillColor = AppColors.accentGreen;
        timeTextColor = AppColors.accentGreen;
      }
    }

    // Show check icon only for regular 'masuk' entries
    bool showCheckIcon =
        absence.status?.toLowerCase() == 'masuk'; // Safely call toLowerCase

    // Determine the date to display: use checkIn for attendance, createdAt for requests
    final DateTime? displayDate = absence.attendanceDate;

    final String formattedDate = displayDate != null
        ? DateFormat('E, MMM d,EEEE').format(displayDate)
        : 'N/A'; // Fallback for date

    return Card(
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5.0,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRequestType
                                ? statusPillColor
                                : statusPillColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              if (showCheckIcon)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              Text(
                                isRequestType
                                    ? 'IZIN' // Display "Izin" for request types
                                    : absence.status?.toUpperCase() ??
                                          'N/A', // Safely call toUpperCase
                                style: TextStyle(
                                  color: isRequestType
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isRequestType)
                      Row(
                        children: [
                          _buildTimeColumn(
                            absence.checkIn?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                'N/A', // Provide fallback for checkIn
                            'Check In',
                            timeTextColor,
                          ),
                          const SizedBox(width: 20),
                          _buildTimeColumn(
                            absence.checkOut?.toLocal().toString().substring(
                                  11,
                                  19,
                                ) ??
                                'N/A',
                            'Check Out',
                            timeTextColor,
                          ),
                          const SizedBox(width: 20),
                          _buildTimeColumn(
                            _calculateWorkingHours(
                              absence.checkIn,
                              absence.checkOut,
                            ),
                            'Working HR\'s',
                            timeTextColor,
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Reason: ${absence.alasanIzin?.split(':').last.trim() ?? 'N/A'}', // Display the reason part of alasan_izin
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.grey.withOpacity(0.7)),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.background,
                      title: const Text('Cancel Entry'),
                      content: const Text(
                        'Are you sure you want to cancel this entry?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'No',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      // Call deleteAbsence from ApiService
                      final ApiResponse<Absence> deleteResponse =
                          await _apiService.deleteAbsence(absence.id);

                      if (deleteResponse.statusCode == 200) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(deleteResponse.message)),
                        );
                        await _refreshList(); // Refresh the list after successful deletion
                        MainBottomNavigationBar.refreshHomeNotifier.value =
                            true; // Signal HomeScreen to refresh
                      } else {
                        String errorMessage = deleteResponse.message;
                        if (deleteResponse.errors != null) {
                          deleteResponse.errors!.forEach((key, value) {
                            errorMessage +=
                                '\n$key: ${(value as List).join(', ')}';
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to cancel entry: $errorMessage',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'An error occurred during cancellation: $e',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String time, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Attendance Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              // final result = await Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const AddTemporary()),
              // );
              // if (result == true) {
              //   _refreshList();
              //   MainBottomNavigationBar.refreshHomeNotifier.value = true;
              // }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Monthly',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectMonth(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat(
                            'MMM', // Corrected format string
                          ).format(_selectedMonth).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.textDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshList,
              child: FutureBuilder<List<Absence>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final attendances = snapshot.data ?? [];

                  if (attendances.isEmpty) {
                    return Center(
                      child: Text(
                        'No attendance records found for ${DateFormat('MMMM').format(_selectedMonth)}.',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceTile(attendances[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
