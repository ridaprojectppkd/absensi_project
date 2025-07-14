import 'dart:async';
import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/models/app_model.dart';
import 'package:absensi_project/screens/main_bottom_navigator_bar.dart';
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
  late Future<List<Absence>> _attendanceFuture;
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
      _refreshList();
      widget.refreshNotifier.value = false;
    }
  }

  Future<List<Absence>> _fetchAndFilterAttendances() async {
    final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
    final String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

    try {
      final ApiResponse<List<Absence>> response = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      if (response.statusCode == 200 && response.data != null) {
        final List<Absence> fetchedAbsences = response.data!;
        fetchedAbsences.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return fetchedAbsences;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: $e')),
        );
      }
      return [];
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
    if (checkIn == null) return '00:00:00';
    DateTime endDateTime = checkOut ?? DateTime.now();
    final Duration duration = endDateTime.difference(checkIn);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getBackgroundColor(String? status) {
    if (status == null) return Colors.grey.shade100;

    switch (status.toLowerCase()) {
      case 'izin':
        return Colors.orange.shade50;
      case 'masuk':
        return Colors.green.shade50;
      case 'late':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildAttendanceTile(Absence absence) {
    final bool isRequestType = absence.status?.toLowerCase() == 'izin';
    final DateTime? displayDate = absence.attendanceDate ?? absence.createdAt;
    final Color backgroundColor = _getBackgroundColor(absence.status);
    final Color primaryColor = isRequestType
        ? Colors.orange.shade200
        : Colors.green;
    final Color textColor = isRequestType
        ? Colors.orange.shade800
        : Colors.green.shade800;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Column
                Column(
                  children: [
                    Text(
                      displayDate != null
                          ? DateFormat('d').format(displayDate)
                          : '--',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      displayDate != null
                          ? DateFormat('EEE').format(displayDate).toUpperCase()
                          : '---',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRequestType
                            ? absence.alasanIzin?.split(':').last.trim() ??
                                  'Request'
                            : 'Attendance Record',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isRequestType) ...[
                        Row(
                          children: [
                            _buildTimeInfo(
                              'Check In',
                              absence.checkIn?.toLocal().toString().substring(
                                    11,
                                    19,
                                  ) ??
                                  '--:--',
                              textColor,
                            ),
                            const SizedBox(width: 16),
                            _buildTimeInfo(
                              'Check Out',
                              absence.checkOut?.toLocal().toString().substring(
                                    11,
                                    19,
                                  ) ??
                                  '--:--',
                              textColor,
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          '9:00 AM',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor, width: 1),
                  ),
                  child: Text(
                    isRequestType
                        ? 'IZIN'
                        : absence.status?.toUpperCase() ?? 'N/A',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (!isRequestType) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: textColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Working Hours: ${_calculateWorkingHours(absence.checkIn, absence.checkOut)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
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
              // Add new attendance logic here
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
                            'MMM',
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
                      final attendance = attendances[index];
                      return Dismissible(
                        key: Key(attendance.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.background,
                              title: const Text('Cancel Entry'),
                              content: const Text(
                                'Are you sure you want to cancel this entry?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    'No',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Yes',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          try {
                            final ApiResponse<Absence> deleteResponse =
                                await _apiService.deleteAbsence(attendance.id);
                            if (deleteResponse.statusCode == 200) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(deleteResponse.message)),
                              );
                              await _refreshList();
                              MainBottomNavigationBar
                                      .refreshHomeNotifier
                                      .value =
                                  true;
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete: $e')),
                              );
                            }
                          }
                        },
                        child: _buildAttendanceTile(attendance),
                      );
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
