// import 'dart:async';
// import 'dart:math'; // Import for pi

// import 'package:absensi_project/constants/app_colors.dart';
// import 'package:absensi_project/models/app_model.dart';
// import 'package:absensi_project/services/api_services.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class PersonReportScreen extends StatefulWidget {
//   final ValueNotifier<bool> refreshNotifier;

//   const PersonReportScreen({super.key, required this.refreshNotifier});

//   @override
//   State<PersonReportScreen> createState() => _PersonReportScreenState();
// }

// class _PersonReportScreenState extends State<PersonReportScreen> {
//   final ApiService _apiService = ApiService();

//   late Future<void>
//       _reportDataFuture; // Changed to void as we update state directly
//   DateTime _selectedMonth = DateTime(
//     DateTime.now().year,
//     DateTime.now().month,
//     1,
//   );

//   // Summary counts for the selected month - Initialized directly to avoid LateInitializationError
//   int _presentCount = 0;
//   int _absentCount =
//       0; // Will now include all non-regular attendance types (izin)
//   int _lateInCount = 0; // Mapped from total_absen in AbsenceStats
//   int _totalWorkingDaysInMonth =
//       0; // Will be derived from presentCount for simplicity
//   String _totalWorkingHours = '0hr';

//   // Data for Bar Chart
//   List<BarChartGroupData> _barChartGroups = [];

//   @override
//   void initState() {
//     super.initState();
//     _reportDataFuture = _fetchAndCalculateMonthlyReports();

//     widget.refreshNotifier.addListener(_handleRefreshSignal);
//   }

//   @override
//   void dispose() {
//     widget.refreshNotifier.removeListener(_handleRefreshSignal);
//     super.dispose();
//   }

//   void _handleRefreshSignal() {
//     if (widget.refreshNotifier.value) {
//       print(
//         'PersonReportScreen: Refresh signal received, refreshing reports...',
//       );
//       setState(() {
//         _reportDataFuture = _fetchAndCalculateMonthlyReports();
//       });
//       widget.refreshNotifier.value = false;
//     }
//   }

//   // Fetches attendance data and calculates monthly summaries
//   Future<void> _fetchAndCalculateMonthlyReports() async {
//     try {
//       // 1. Fetch Absence Stats for summary counts
//       final ApiResponse<AbsenceStats> statsResponse =
//           await _apiService.getAbsenceStats();
//       if (statsResponse.statusCode == 200 && statsResponse.data != null) {
//         final AbsenceStats stats = statsResponse.data!;
//         setState(() {
//           _presentCount = stats.totalMasuk;
//           _absentCount = stats
//               .totalIzin; // Assuming total_izin covers all types of absences/leaves
//           _lateInCount =
//               stats.totalAbsen; // Assuming total_absen covers late entries
//           // Calculate total working days in the selected month
//           _totalWorkingDaysInMonth = _getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
//         });
//       } else {
//         print('Failed to get absence stats: ${statsResponse.message}');
//         _updateSummaryCounts(0, 0, 0, 0, '0hr'); // Reset counts on error
//         _updateBarChartData(0, 0, 0); // Reset bar chart data on error
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Failed to load summary: ${statsResponse.message}'),
//             ),
//           );
//         }
//         return; // Exit if stats fetching fails
//       }

//       // 2. Fetch Absence History for total working hours calculation
//       final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
//       final String endDate = DateFormat('yyyy-MM-dd').format(
//         DateTime(
//           _selectedMonth.year,
//           _selectedMonth.month + 1,
//           0,
//         ), // Last day of the month
//       );

//       final ApiResponse<List<Absence>> historyResponse = await _apiService
//           .getAbsenceHistory(startDate: startDate, endDate: endDate);

//       Duration totalWorkingDuration = Duration.zero;
//       if (historyResponse.statusCode == 200 && historyResponse.data != null) {
//         for (var absence in historyResponse.data!) {
//           // Only count working hours for 'masuk' entries that have both checkIn and checkOut
//           if (absence.status?.toLowerCase() ==
//                   'masuk' && // Safely call toLowerCase
//               absence.checkIn != null && // Added null check for checkIn
//               absence.checkOut != null) {
//             totalWorkingDuration += absence.checkOut!.difference(
//               absence.checkIn!, // Added null assertion for checkIn
//             );
//           }
//         }
//       } else {
//         print(
//           'Failed to get absence history for working hours: ${historyResponse.message}',
//         );
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to load working hours: ${historyResponse.message}',
//               ),
//             ),
//           );
//         }
//       }

//       final int totalHours = totalWorkingDuration.inHours;
//       final int remainingMinutes = totalWorkingDuration.inMinutes.remainder(60);
//       String formattedTotalWorkingHours =
//           '${totalHours}hr ${remainingMinutes}min';

//       setState(() {
//         _totalWorkingHours = formattedTotalWorkingHours;
//       });

//       // Update bar chart data after all counts are finalized
//       _updateBarChartData(_presentCount, _absentCount, _lateInCount);
//     } catch (e) {
//       print('Error fetching and calculating monthly reports: $e');
//       _updateSummaryCounts(0, 0, 0, 0, '0hr'); // Reset counts on error
//       _updateBarChartData(0, 0, 0); // Reset bar chart data on error
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('An error occurred loading reports: $e')),
//         );
//       }
//     }
//   }

//   // Helper function to get the number of days in a given month
//   int _getDaysInMonth(int year, int month) {
//     return DateTime(year, month + 1, 0).day;
//   }

//   // Updates the state variables for summary counts
//   void _updateSummaryCounts(
//     int present,
//     int absent,
//     int late,
//     int totalWorkingDays,
//     String totalHrs,
//   ) {
//     setState(() {
//       _presentCount = present;
//       _absentCount = absent;
//       _lateInCount = late;
//       _totalWorkingDaysInMonth = totalWorkingDays;
//       _totalWorkingHours = totalHrs;
//     });
//   }

//   // New method to update bar chart data
//   void _updateBarChartData(int presentCount, int absentCount, int lateInCount) {
//     setState(() {
//       _barChartGroups = [
//         BarChartGroupData(
//           x: 0,
//           barRods: [
//             BarChartRodData(
//               toY: presentCount.toDouble(),
//               color: Colors.green,
//               width: 20,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ],
//           showingTooltipIndicators: [0],
//         ),
//         BarChartGroupData(
//           x: 1,
//           barRods: [
//             BarChartRodData(
//               toY: absentCount.toDouble(),
//               color: Colors.red,
//               width: 20,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ],
//           showingTooltipIndicators: [0],
//         ),
//         BarChartGroupData(
//           x: 2,
//           barRods: [
//             BarChartRodData(
//               toY: lateInCount.toDouble(),
//               color: Colors.orange,
//               width: 20,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ],
//           showingTooltipIndicators: [0],
//         ),
//       ];
//     });
//   }

//   // Helper for BarChart titles (labels)
//   Widget getTitles(double value, TitleMeta meta) {
//     // Re-added 'TitleMeta meta'
//     const style = TextStyle(
//       color: AppColors.textDark,
//       fontWeight: FontWeight.bold,
//       fontSize: 14,
//     );
//     String text;
//     switch (value.toInt()) {
//       case 0:
//         text = 'Present';
//         break;
//       case 1:
//         text = 'Absent';
//         break;
//       case 2:
//         text = 'Late';
//         break;
//       default:
//         text = '';
//         break;
//     }
//     return SideTitleWidget(
//       meta: meta,
//       space: 4.0,
//       child: Text(text, style: style),
//     );
//   }

//   // Method to show month picker (only month and year)
//   Future<void> _selectMonth(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedMonth,
//       firstDate: DateTime(2000, 1, 1),
//       lastDate: DateTime(2101, 12, 31),
//       initialDatePickerMode: DatePickerMode.year, // Start with year selection
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppColors.primary,
//               onPrimary: Colors.white,
//               onSurface: AppColors.textDark,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(foregroundColor: AppColors.primary),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       final DateTime newSelectedMonth = DateTime(picked.year, picked.month, 1);
//       if (newSelectedMonth.year != _selectedMonth.year ||
//           newSelectedMonth.month != _selectedMonth.month) {
//         setState(() {
//           _selectedMonth = newSelectedMonth;
//           _reportDataFuture =
//               _fetchAndCalculateMonthlyReports(); // Trigger re-fetch
//         });
//       }
//     }
//   }

//   // START: MODIFIED _buildSummaryCard WIDGET
//   // Helper widget to build summary cards with circular progress indicator
//   Widget _buildSummaryCard(String title, int count, Color color, int totalDays) {
//     double percentage = totalDays > 0 ? (count / totalDays) : 0.0;
//     if (percentage > 1.0) percentage = 1.0; // Cap percentage at 100%

//     return Expanded(
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.background,
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 3,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(
//               width: 80, // Adjust size as needed
//               height: 80, // Adjust size as needed
//               child: CustomPaint(
//                 painter: _CircularProgressPainter(
//                   progress: percentage,
//                   color: color,
//                 ),
//                 child: Center(
//                   child: Text(
//                     count.toString(),
//                     style: TextStyle(
//                       color: AppColors.textDark,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 24,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.black87,
//                 fontSize: 12, // Smaller font for title
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   // END: MODIFIED _buildSummaryCard WIDGET

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Attendance Reports'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: FutureBuilder<void>(
//         future: _reportDataFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           // Data is loaded, build the UI
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Monthly Summary',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.textDark,
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () => _selectMonth(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Row(
//                           children: [
//                             Text(
//                               DateFormat(
//                                 'MMM yyyy', // Corrected format string to show year
//                               ).format(_selectedMonth).toUpperCase(),
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.textDark,
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                             const Icon(
//                               Icons.calendar_today,
//                               size: 16,
//                               color: AppColors.textDark,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Summary cards for the selected month in a 3x2 grid
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: GridView.count(
//                   crossAxisCount: 3,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   mainAxisSpacing: 10,
//                   crossAxisSpacing: 10,
//                   childAspectRatio: 1.0,
//                   children: [
//                     // START: UPDATED _buildSummaryCard USAGE
//                     _buildSummaryCard(
//                       'Present',
//                       _presentCount,
//                       Colors.green,
//                       _totalWorkingDaysInMonth,
//                     ),
//                     _buildSummaryCard(
//                       'Absent',
//                       _absentCount,
//                       Colors.red,
//                       _totalWorkingDaysInMonth,
//                     ),
//                     _buildSummaryCard(
//                       'Late',
//                       _lateInCount,
//                       Colors.orange,
//                       _totalWorkingDaysInMonth,
//                     ),
//                     // END: UPDATED _buildSummaryCard USAGE
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 21),
//               const Padding(
//                 padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
//                 child: Text(
//                   'Attendance Status Breakdown',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textDark,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 150), // Spacer for bar chart
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: BarChart(
//                     BarChartData(
//                       barGroups: _barChartGroups,
//                       borderData: FlBorderData(show: false),
//                       titlesData: FlTitlesData(
//                         show: true,
//                         bottomTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             getTitlesWidget: getTitles,
//                             reservedSize: 30,
//                           ),
//                         ),
//                         leftTitles: const AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         topTitles: const AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         rightTitles: const AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                       ),
//                       gridData: const FlGridData(show: false),
//                       barTouchData: BarTouchData(
//                         touchTooltipData: BarTouchTooltipData(
//                           getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                             String label;
//                             switch (group.x.toInt()) {
//                               case 0:
//                                 label = 'Present';
//                                 break;
//                               case 1:
//                                 label = 'Absent';
//                                 break;
//                               case 2:
//                                 label = 'Late';
//                                 break;
//                               default:
//                                 label = '';
//                             }
//                             return BarTooltipItem(
//                               '$label\n',
//                               const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                               children: <TextSpan>[
//                                 TextSpan(
//                                   text: rod.toY.toStringAsFixed(0),
//                                   style: const TextStyle(
//                                     color: Colors.yellow,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// // START: NEW CUSTOMPAINTER FOR CIRCULAR PROGRESS
// class _CircularProgressPainter extends CustomPainter {
//   final double progress;
//   final Color color;

//   _CircularProgressPainter({required this.progress, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final strokeWidth = 5.0;
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

//     // Background circle
//     final backgroundPaint = Paint()
//       ..color = Colors.grey.shade300 // Light grey for the background ring
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//     canvas.drawCircle(center, radius, backgroundPaint);

//     // Foreground arc
//     final foregroundPaint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;

//     double sweepAngle = 2 * pi * progress; // 2 * pi for a full circle
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -pi / 2, // Start from the top
//       sweepAngle,
//       false,
//       foregroundPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
//     return oldDelegate.progress != progress || oldDelegate.color != color;
//   }
// }
// // END: NEW CUSTOMPAINTER FOR CIRCULAR PROGRESS
