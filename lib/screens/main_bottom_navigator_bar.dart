import 'package:absensi_project/screens/attendance/attendance_list_screen.dart';
import 'package:absensi_project/screens/auth/profile_screen.dart';
import 'package:absensi_project/screens/home_screen.dart';
import 'package:flutter/material.dart';

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({super.key});

  // Declare ValueNotifiers as static final members of the StatefulWidget itself
  static final ValueNotifier<bool> refreshHomeNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> refreshAttendanceNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> refreshProfileNotifier = ValueNotifier<bool>(false);

  @override
  State<MainBottomNavigationBar> createState() => _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _selectedIndex = 0; // Start with Home tab (index 0)

  late final List<Widget> _widgetOptions;

  // List of items for the custom bottom navigation bar
  final List<CustomBottomBarItem> _navItems = [
    CustomBottomBarItem(
      icon: Icons.home_rounded,
      label: 'Home',
      color: Colors.blue,
    ),
    CustomBottomBarItem(
      icon: Icons.calendar_today_rounded,
      label: 'Attendance',
      color: Colors.green,
    ),
    CustomBottomBarItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(
        refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier,
      ),
      AttendanceListScreen(
        refreshNotifier: MainBottomNavigationBar.refreshAttendanceNotifier,
      ),
      ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshProfileNotifier,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Trigger refresh notifiers for the respective tabs
    if (index == 0) {
      MainBottomNavigationBar.refreshHomeNotifier.value = true;
    } else if (index == 1) {
      MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
    } else if (index == 2) {
      MainBottomNavigationBar.refreshProfileNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomBarLabelSlide(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}

/// Model untuk item di CustomBottomBarLabelSlide.
class CustomBottomBarItem {
  final IconData icon;
  final String label;
  final Color color;

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
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onItemSelected(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: double.infinity,
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
                          height: 45,
                          width: (MediaQuery.of(context).size.width / items.length) * 0.8,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
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
                            height: isSelected ? 20 : 0,
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