import 'package:absensi_project/screens/attendance/attendance_list_screen.dart';
import 'package:absensi_project/screens/attendance/request_screen.dart';
import 'package:absensi_project/screens/auth/profile_screen.dart';
import 'package:absensi_project/screens/home_screen.dart';
import 'package:absensi_project/screens/reports/person_report_screen.dart';
import 'package:flutter/material.dart';

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({super.key});

  // Declare ValueNotifiers as static final members of the StatefulWidget itself
  // This makes them globally accessible using MainBottomNavigationBar.notifierName
  static final ValueNotifier<bool> refreshHomeNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<bool> refreshAttendanceNotifier =
      ValueNotifier<bool>(false);
  // ValueNotifier for PersonReportScreen
  static final ValueNotifier<bool> refreshReportsNotifier = ValueNotifier<bool>(
    false,
  );
  // NEW: ValueNotifier for ProfileScreen
  static final ValueNotifier<bool> refreshProfileNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<bool> refreshRequestsNotifier =
      ValueNotifier<bool>(false);

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _selectedIndex = 0; // Start with Home tab (index 0)

  late final List<Widget> _widgetOptions;

  // NEW: List of items for the custom bottom navigation bar
  final List<CustomBottomBarItem> _navItems = [
    CustomBottomBarItem(
      icon: Icons.home_rounded,
      label: 'Home',
      color: Colors.blue, // Warna untuk item Home
    ),
    CustomBottomBarItem(
      icon: Icons.calendar_today_rounded,
      label: 'Attendance',
      color: Colors.green, // Warna untuk item Attendance
    ),
    CustomBottomBarItem(
      icon: Icons.add,
      label: 'Requests',
      color: Colors.pink, // Warna untuk item Requests (index 2)
    ),
    CustomBottomBarItem(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      color: Colors.orange, // Warna untuk item Reports (index 3)
    ),
    CustomBottomBarItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      color: Colors.purple, // Warna untuk item Profile (index 4)
    ),
  ];

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // HomeScreen is now the actual content for the first tab.
      // We pass the refreshHomeNotifier to it so it can listen for external refresh signals.
      HomeScreen(
        refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier,
      ), // Access via widget name
      // AttendanceListScreen: Now accepts refreshAttendanceNotifier to listen for updates.
      AttendanceListScreen(
        refreshNotifier: MainBottomNavigationBar.refreshAttendanceNotifier,
      ), // Access via widget name
      // RequestScreen is still in the IndexedStack, but its tab will now push a new route
      RequestScreen(
        refreshNotifier: MainBottomNavigationBar.refreshRequestsNotifier,
      ), // Access via widget name
      // Pass the new refreshReportsNotifier to PersonReportScreen
      PersonReportScreen(
        refreshNotifier: MainBottomNavigationBar.refreshReportsNotifier,
      ), // Content for the third tab
      // FIX: Pass the new refreshProfileNotifier to ProfileScreen
      ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshProfileNotifier,
      ), // Content for the fourth tab
    ];
  }

  /// Handles the tap event on a BottomNavigationBarItem.
  ///
  /// Updates the [_selectedIndex] to switch the displayed screen in the IndexedStack.
  void _onItemTapped(int index) async {
    // Made async to await Navigator.push
    if (index == 2) {
      // This is the 'Requests' tab
      // Do not change _selectedIndex immediately for the IndexedStack.
      // Instead, push the RequestScreen as a new full-screen route.
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RequestScreen(
            refreshNotifier: MainBottomNavigationBar.refreshRequestsNotifier,
          ),
        ),
      );

      // After RequestScreen is popped, check the result
      if (result == true) {
        // If request was submitted successfully, navigate back to Home tab (index 0)
        // and trigger a refresh for Home and Attendance.
        setState(() {
          _selectedIndex = 0; // Set selected index to Home tab
        });
        MainBottomNavigationBar.refreshHomeNotifier.value = true;
        MainBottomNavigationBar.refreshAttendanceNotifier.value =
            true; // Also refresh attendance as it might be related
      }
      // If result is not true (e.g., user just went back without submitting),
      // the current tab remains active (the one that was active before pushing RequestScreen).
    } else {
      // For all other tabs (Home, Attendance, Reports, Profile)
      if (_selectedIndex != index) {
        setState(() {
          _selectedIndex = index;
        });
      }

      // Trigger refresh notifiers for the respective tabs
      if (index == 0) {
        MainBottomNavigationBar.refreshHomeNotifier.value = true;
      } else if (index == 1) {
        MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
      } else if (index == 3) {
        // Reports tab (index 3 in _widgetOptions)
        MainBottomNavigationBar.refreshReportsNotifier.value = true;
      } else if (index == 4) {
        // Profile tab (index 4 in _widgetOptions)
        MainBottomNavigationBar.refreshProfileNotifier.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      // START: MODIFIKASI BOTTOM NAVIGATION BAR
      bottomNavigationBar: CustomBottomBarLabelSlide(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: _navItems,
      ),
      // END: MODIFIKASI BOTTOM NAVIGATION BAR
    );
  }
}

// START: IMPLEMENTASI KUSTOM BOTTOM_BAR_LABEL_SLIDE
/// Model untuk item di CustomBottomBarLabelSlide.
class CustomBottomBarItem {
  final IconData icon;
  final String label;
  final Color color;
  // Warna spesifik untuk item ini

  CustomBottomBarItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// Implementasi kustom dari BottomBarLabelSlide.
class CustomBottomBarLabelSlide extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<CustomBottomBarItem> items;

  const CustomBottomBarLabelSlide({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Tinggi tetap untuk navigation bar
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ), // Sudut melengkung di atas
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onItemSelected(index),
              behavior: HitTestBehavior
                  .opaque, // Memastikan seluruh area Expanded bisa di-tap
              child: SizedBox(
                height: double.infinity, // Memenuhi tinggi parent
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sliding background for selected item
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: isSelected
                          ? 0
                          : (MediaQuery.of(context).size.width / items.length) *
                                (index - selectedIndex),
                      right: isSelected
                          ? 0
                          : (MediaQuery.of(context).size.width / items.length) *
                                (selectedIndex - index),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isSelected ? 1.0 : 0.0,
                        child: Container(
                          height: 45, // Tinggi background yang meluncur
                          width:
                              (MediaQuery.of(context).size.width /
                                  items.length) *
                              0.8, // Lebar disesuaikan
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(
                              0.2,
                            ), // Warna background dengan opacity
                            borderRadius: BorderRadius.circular(
                              25,
                            ), // Sudut melengkung
                          ),
                        ),
                      ),
                    ),
                    // Icon and Label
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected ? item.color : Colors.grey.shade600,
                          size: 26,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            height: isSelected
                                ? 20
                                : 0, // Tinggi label saat muncul/hilang
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isSelected ? 1.0 : 0.0,
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: item.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
