import 'package:absensi_project/models/app_model.dart';
import 'package:absensi_project/screens/auth/edit_profile_screen.dart';
import 'package:absensi_project/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Keep this import for DateFormat if you use it for displaying dates in UI

import '../../routes/app_routes.dart'; // Your AppRoutes

// NEW: Import ThemeProvider
// Asumsikan Anda akan menambahkan provider ke pubspec.yaml

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const ProfileScreen({super.key, required this.refreshNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  User? _currentUser; // Holds the full user data (from API)
  bool _isLoading = false; // Add loading state

  bool _notificationEnabled = true; // State for the notification switch

  @override
  void initState() {
    super.initState();
    _loadUserData();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _loadUserData(); // Re-fetch user data on refresh signal
      widget.refreshNotifier.value = false; // Reset the notifier
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    final ApiResponse<User> response = await _apiService.getProfile();

    setState(() {
      _isLoading = false; // Set loading to false
    });

    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _currentUser = response.data;
        // You might also want to load the notification preference from the user model
        // if you store it there:
        // _notificationEnabled = user?.notificationPreference ?? true;
      });
    } else {
      ('Failed to load user profile: ${response.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${response.message}'),
          ),
        );
      }
      setState(() {
        _currentUser = null; // Ensure _currentUser is null on error
      });
    }
  }

  void _logout(BuildContext context) async {
    await ApiService.clearToken(); // Clear token using ApiService static method
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _navigateToEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not loaded yet. Please wait.')),
      );
      return;
    }

    // Navigate to the EditProfileScreen, passing the current user data.
    // Await the result to know if data was updated.
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _currentUser!),
      ),
    );

    // If result is true, it means the profile was successfully updated in EditProfileScreen,
    // so refresh the data on this ProfileScreen.
    if (result == true) {
      _loadUserData(); // Refresh profile data
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide default values if _currentUser is null (e.g., still loading or no user logged in)
    final String username =
        _currentUser?.name ?? 'Guest User'; // Use .name property
    final String email = _currentUser?.email ?? 'guest@example.com';
    final String jenisKelamin = _currentUser?.jenis_kelamin == 'L'
        ? 'Laki-laki'
        : _currentUser?.jenis_kelamin == 'P'
        ? 'Perempuan'
        : 'N/A';
    // Changed: profilePhotoUrl will now hold the URL/path from the API
    final String profilePhotoUrl = _currentUser?.profile_photo ?? '';

    // Use training_title from API for designation
    final String designation = _currentUser?.training_title ?? 'Employee';

    // Format the joinedDate based on batch.start_date from User model
    String formattedJoinedDate = 'N/A';
    if (_currentUser?.batch?.startDate != null) {
      try {
        // Added null assertion (!) to startDate as DateTime.parse expects a non-nullable String
        final DateTime startDate = DateTime.parse(
          _currentUser!.batch!.startDate!,
        );
        formattedJoinedDate = DateFormat('MMM dd, yyyy').format(startDate);
      } catch (e) {
        print('Error parsing batch start date: $e');
        formattedJoinedDate = 'N/A';
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Center(child: Text('Profile')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // Managed by MainBottomNavigationBar
      ),
      body: Stack(
        children: [
          // Blue background wave/area at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150, // Height of the blue background
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
          ),
          // Conditional rendering: Show CircularProgressIndicator while _isLoading is true
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(), // Show loading indicator
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  children: [
                    // Profile Header Section (Avatar, Name, Designation, Joined Date)
                    _buildProfileHeader(
                      username,
                      designation,
                      formattedJoinedDate,
                      profilePhotoUrl, // Pass URL/path string
                    ),
                    const SizedBox(height: 20), // Space between sections
                    // User Details Card
                    _buildUserDetailsCard(
                      email,
                      _currentUser?.batch_ke, // Pass batch_ke
                      jenisKelamin, // Pass jenisKelamin
                    ),
                    const SizedBox(height: 20),

                    // Settings and Logout Options
                    _buildActionOptions(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String username,
    String designation,
    String joinedDate,
    String profilePhotoPath, // Changed to profilePhotoPath
  ) {
    ImageProvider<Object>? imageProvider;

    // Construct full URL based on whether it's already a full URL or a relative path
    if (profilePhotoPath.isNotEmpty) {
      final String fullImageUrl = profilePhotoPath.startsWith('http')
          ? profilePhotoPath
          : 'https://appabsensi.mobileprojp.com/public/' +
                profilePhotoPath; // Adjusted base path
      imageProvider = NetworkImage(fullImageUrl);
    }

    return Column(
      children: [
        // Profile Picture
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55, // Larger radius for a prominent profile picture
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary, // MODIFIKASI: Gunakan warna primary dari tema
            backgroundImage: imageProvider, // Use the determined image provider
            child:
                imageProvider ==
                    null // Show icon only if no valid image provider
                ? const Icon(
                    Icons.person, // Fallback icon if no image URL or local file
                    size: 50,
                    color: Colors.white,
                  )
                : null, // No child if an image is loading
          ),
        ),
        const SizedBox(height: 15),
        // User Name
        Text(
          username,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 4),
        // Designation and Joined Date
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              designation,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '-', // Separator
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              'Joined $joinedDate', // Add "Joined " prefix here
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDetailsCard(
    String email,
    String? batchKe, // Added batchKe parameter
    String jenisKelamin, // Added jenisKelamin parameter
  ) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow('Email ID', email),
            if (batchKe != null) ...[
              // Conditionally add batch info
              Divider(color: Theme.of(context).dividerColor, height: 20),
              _buildDetailRow('Batch', batchKe),
            ],
            Divider(color: Theme.of(context).dividerColor, height: 20),
            _buildDetailRow(
              'Jenis Kelamin',
              jenisKelamin,
            ), // New row for Jenis Kelamin
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Notification Toggle
          Card(
            color: Theme.of(context).cardColor,
            margin: EdgeInsets.zero, // No extra margin for this card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Notification',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              trailing: Switch.adaptive(
                value: _notificationEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    _notificationEnabled = newValue;
                  });
                  // Add logic to save notification preference (e.g., to UserModel or SessionManager)
                },
                activeColor: Theme.of(context)
                    .colorScheme
                    .primary, // MODIFIKASI: Gunakan warna primary dari tema
              ),
              onTap: () {
                // Toggling the switch directly is often enough, but you can add more logic here.
                setState(() {
                  _notificationEnabled = !_notificationEnabled;
                });
              },
            ),
          ),
          const SizedBox(height: 10), // Space between cards
          // NEW: Dark Mode Toggle
          // Card(
          //   color: Theme.of(context).cardColor,
          //   margin: EdgeInsets.zero,
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(15),
          //   ),
          //   elevation: 4,
          //   child: Consumer<ThemeProvider>(
          //     builder: (context, themeProvider, child) {
          //       return ListTile(
          //         leading: Icon(
          //           themeProvider.themeMode == ThemeMode.dark
          //               ? Icons.dark_mode
          //               : Icons.light_mode,
          //           color: Theme.of(context).colorScheme.primary,
          //         ),
          //         title: Text(
          //           'Dark Mode',
          //           style: TextStyle(
          //             fontSize: 16,
          //             color: Theme.of(context).colorScheme.onBackground,
          //           ),
          //         ),
          //         trailing: Switch.adaptive(
          //           value: themeProvider.themeMode == ThemeMode.dark,
          //           onChanged: (bool newValue) {
          //             themeProvider.toggleTheme(newValue);
          //           },
          //           activeColor: Theme.of(context)
          //               .colorScheme
          //               .primary, // MODIFIKASI: Gunakan warna primary dari tema
          //         ),
          //         onTap: () {
          //           // FIX: Gunakan null-aware operator (?) pada themeProvider.toggleTheme
          //           // Ini mencegah error jika themeProvider entah bagaimana null (meskipun seharusnya tidak dengan Consumer)
          //           themeProvider.toggleTheme(
          //             themeProvider.themeMode != ThemeMode.dark,
          //           ); // MODIFIKASI: Hapus null-aware operator karena Consumer menjamin tidak null
          //         },
          //       );
          //     },
          //   ),
          // ),
          const SizedBox(height: 10), // Space between cards
          // Settings Option (now navigates to EditProfileScreen)
          Card(
            color: Theme.of(context).cardColor,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onTap: _navigateToEditProfile, // Call the new navigation method
            ),
          ),
          const SizedBox(height: 10), // Space between cards
          // Logout Option
          Card(
            color: Theme.of(context).cardColor,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ), // MODIFIKASI: Gunakan warna error dari tema
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ), // MODIFIKASI: Gunakan warna error dari tema
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onTap: () => _logout(context),
            ),
          ),

          const SizedBox(height: 20), // Space at the bottom
          Card(
            color: Theme.of(context).cardColor,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ],
      ),
    );
  }
}
