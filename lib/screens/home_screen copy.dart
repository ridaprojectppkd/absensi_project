// import 'dart:async';

// import 'package:absensi_project/constants/app_colors.dart';
// import 'package:absensi_project/models/app_model.dart';
// import 'package:absensi_project/screens/buttom_navigator_bar.dart';

// import 'package:absensi_project/services/api_services.dart';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart'; // For reverse geocoding
// import 'package:geolocator/geolocator.dart'; // For geolocation
// import 'package:intl/intl.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import for Google Maps

// class HomeScreen extends StatefulWidget {
//   final ValueNotifier<bool> refreshNotifier;
//   const HomeScreen({super.key, required this.refreshNotifier});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ApiService _apiService = ApiService();

//   String _userName = 'User';
//   String _location = 'Getting Location...';
//   String _currentDate = '';
//   String _currentTime = '';
//   String _profilePhotoUrl = '';
//   Timer? _timer;

//   AbsenceToday? _todayAbsence; // Changed from AttendanceModel to AbsenceToday
//   AbsenceStats? _absenceStats; // New state for attendance statistics

//   Position? _currentPosition;
//   bool _permissionGranted = false;
//   bool _isCheckingInOrOut = false; // To prevent multiple taps during API calls

//   // Google Maps related state
//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};
//   LatLng? _initialCameraPosition; // To store the initial map center

//   @override
//   void initState() {
//     super.initState();
//     _updateDateTime();
//     _determinePosition(); // Start location fetching
//     _loadUserData();
//     _fetchAttendanceData(); // Fetch initial attendance data

//     widget.refreshNotifier.addListener(_handleRefreshSignal);

//     _timer = Timer.periodic(
//       const Duration(seconds: 1),
//       (_) => _updateDateTime(),
//     );
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _mapController?.dispose(); // Dispose map controller
//     widget.refreshNotifier.removeListener(_handleRefreshSignal);
//     super.dispose();
//   }

//   void _handleRefreshSignal() {
//     if (widget.refreshNotifier.value) {
//       _fetchAttendanceData(); // Re-fetch data for the home screen
//       widget.refreshNotifier.value = false; // Reset the notifier after handling
//     }
//   }

//   Future<void> _loadUserData() async {
//     final ApiResponse<User> response = await _apiService.getProfile();
//     if (response.statusCode == 200 && response.data != null) {
//       setState(() {
//         _userName = response.data!.name;
//         _profilePhotoUrl = response.data!.profile_photo ?? '';
//       });
//     } else {
//       print('Failed to load user profile: ${response.message}');
//       setState(() {
//         _userName = 'User'; // Default if profile fails
//       });
//     }
//   }

//   void _updateDateTime() {
//     final now = DateTime.now();
//     setState(() {
//       _currentDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
//       _currentTime = DateFormat('HH:mm:ss').format(now);
//     });
//   }

//   Future<void> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Location services are not enabled don't continue
//       // accessing the position and request users of the
//       // App to enable the location services.
//       if (mounted) {
//         _showErrorDialog('Location services are disabled. Please enable them.');
//       }
//       setState(() {
//         _location = 'Location services disabled';
//         _permissionGranted = false;
//       });
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         // Permissions are denied, next time you could try
//         // requesting permissions again (this is also where
//         // Android's shouldShowRequestPermissionRationale
//         // returned true. According to Android guidelines
//         // your App should show an explanatory UI now.
//         if (mounted) {
//           _showErrorDialog(
//             'Location permissions are denied. Please grant them in settings.',
//           );
//         }
//         setState(() {
//           _location = 'Location permissions denied';
//           _permissionGranted = false;
//         });
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, handle appropriately.
//       if (mounted) {
//         _showErrorDialog(
//           'Location permissions are permanently denied, we cannot request permissions.',
//         );
//       }
//       setState(() {
//         _location = 'Location permissions permanently denied';
//         _permissionGranted = false;
//       });
//       return;
//     }

//     // When we reach here, permissions are granted and we can
//     // continue accessing the position of the device.
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       setState(() {
//         _currentPosition = position;
//         _permissionGranted = true;
//         _initialCameraPosition = LatLng(position.latitude, position.longitude);
//         _addMarker(
//           LatLng(position.latitude, position.longitude),
//           'current_location',
//           'Your Current Location',
//         );
//       });
//       await _getAddressFromLatLng(position);
//     } catch (e) {
//       print('Error getting current location: $e');
//       if (mounted) {
//         _showErrorDialog('Failed to get current location: $e');
//       }
//       setState(() {
//         _location = 'Failed to get location';
//         _permissionGranted = false;
//       });
//     }
//   }

//   Future<void> _getAddressFromLatLng(Position position) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       Placemark place = placemarks[0];
//       setState(() {
//         _location =
//             "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
//       });
//     } catch (e) {
//       print('Error getting address from coordinates: $e');
//       setState(() {
//         _location = 'Address not found';
//       });
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     if (_initialCameraPosition != null) {
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_initialCameraPosition!, 15),
//       );
//     }
//   }

//   void _addMarker(LatLng position, String markerId, String title) {
//     setState(() {
//       _markers.add(
//         Marker(
//           markerId: MarkerId(markerId),
//           position: position,
//           infoWindow: InfoWindow(title: title),
//         ),
//       );
//     });
//   }

//   Future<void> _fetchAttendanceData() async {
//     // Fetch today's absence record
//     final ApiResponse<AbsenceToday> todayAbsenceResponse = await _apiService
//         .getAbsenceToday();
//     if (todayAbsenceResponse.statusCode == 200 &&
//         todayAbsenceResponse.data != null) {
//       setState(() {
//         _todayAbsence = todayAbsenceResponse.data;
//       });
//     } else {
//       print('Failed to get today\'s absence: ${todayAbsenceResponse.message}');
//       setState(() {
//         _todayAbsence = null; // Reset if no record or error
//       });
//     }

//     // Fetch attendance statistics////////////////////////////////////////////diganti get histori untuk mengikuti tanggal
//     final ApiResponse<AbsenceStats> statsResponse = await _apiService
//         .getAbsenceStats();
//     if (statsResponse.statusCode == 200 && statsResponse.data != null) {
//       setState(() {
//         _absenceStats = statsResponse.data;
//       });
//     } else {
//       print('Failed to get absence stats: ${statsResponse.message}');
//       setState(() {
//         _absenceStats = null; // Reset if no stats or error
//       });
//     }
//   }

//   Future<void> _handleCheckIn() async {
//     if (!_permissionGranted || _currentPosition == null) {
//       _showErrorDialog(
//         'Location not available. Please ensure location services are enabled and permissions are granted.',
//       );
//       await _determinePosition(); // Try to get location again
//       return;
//     }
//     if (_isCheckingInOrOut) return; // Prevent double tap

//     setState(() {
//       _isCheckingInOrOut = true;
//     });

//     try {
//       final String formattedAttendanceDate = DateFormat(
//         'yyyy-MM-dd',
//       ).format(DateTime.now());
//       // Format the current time to 'HH:mm' string for the API
//       final String formattedCheckInTime = DateFormat(
//         'HH:mm',
//       ).format(DateTime.now());

//       final ApiResponse<Absence> response = await _apiService.checkIn(
//         checkInLat: _currentPosition!.latitude,
//         checkInLng: _currentPosition!.longitude,
//         checkInAddress: _location,
//         status: 'masuk', // Assuming 'masuk' for regular check-in
//         attendanceDate: formattedAttendanceDate,
//         checkInTime: formattedCheckInTime,
//       );

//       if (response.statusCode == 200 && response.data != null) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(response.message)));
//         _fetchAttendanceData(); // Refresh home after check-in
//         MainBottomNavigationBar.refreshAttendanceNotifier.value =
//             true; // Signal AttendanceListScreen
//       } else {
//         String errorMessage = response.message;
//         if (response.errors != null) {
//           response.errors!.forEach((key, value) {
//             errorMessage += '\n$key: ${(value as List).join(', ')}';
//           });
//         }
//         if (mounted) {
//           _showErrorDialog('Check In Failed: $errorMessage');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorDialog('An error occurred during check-in: $e');
//       }
//     } finally {
//       setState(() {
//         _isCheckingInOrOut = false;
//       });
//     }
//   }

//   Future<void> _handleCheckOut() async {
//     if (!_permissionGranted || _currentPosition == null) {
//       _showErrorDialog(
//         'Location not available. Please ensure location services are enabled and permissions are granted.',
//       );
//       await _determinePosition(); // Try to get location again
//       return;
//     }
//     if (_isCheckingInOrOut) return; // Prevent double tap

//     setState(() {
//       _isCheckingInOrOut = true;
//     });

//     try {
//       final String formattedAttendanceDate = DateFormat(
//         'yyyy-MM-dd',
//       ).format(DateTime.now());
//       // Format the current time to 'HH:mm' string for the API
//       final String formattedCheckOutTime = DateFormat(
//         'HH:mm',
//       ).format(DateTime.now());

//       final ApiResponse<Absence> response = await _apiService.checkOut(
//         checkOutLat: _currentPosition!.latitude,
//         checkOutLng: _currentPosition!.longitude,
//         checkOutAddress: _location,
//         attendanceDate: formattedAttendanceDate,
//         checkOutTime: formattedCheckOutTime,
//       );

//       if (response.statusCode == 200 && response.data != null) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(response.message)));
//         _fetchAttendanceData(); // Refresh home after check-out
//         MainBottomNavigationBar.refreshAttendanceNotifier.value =
//             true; // Signal AttendanceListScreen
//       } else {
//         String errorMessage = response.message;
//         if (response.errors != null) {
//           response.errors!.forEach((key, value) {
//             errorMessage += '\n$key: ${(value as List).join(', ')}';
//           });
//         }
//         if (mounted) {
//           _showErrorDialog('Check Out Failed: $errorMessage');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorDialog('An error occurred during check-out: $e');
//       }
//     } finally {
//       setState(() {
//         _isCheckingInOrOut = false;
//       });
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.background,
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK', style: TextStyle(color: AppColors.primary)),
//           ),
//         ],
//       ),
//     );
//   }

//   String _calculateWorkingHours() {
//     if (_todayAbsence == null || _todayAbsence!.jamMasuk == null) {
//       return '00:00:00'; // No check-in yet or jamMasuk is null
//     }

//     final DateTime checkInDateTime =
//         _todayAbsence!.jamMasuk!; // Null-check added
//     DateTime endDateTime;

//     if (_todayAbsence!.jamKeluar != null) {
//       endDateTime = _todayAbsence!.jamKeluar!; // Null-check added
//     } else {
//       endDateTime = DateTime.now(); // Use current time for live calculation
//     }

//     final Duration duration = endDateTime.difference(checkInDateTime);
//     final int hours = duration.inHours;
//     final int minutes = duration.inMinutes.remainder(60);
//     final int seconds = duration.inSeconds.remainder(60);

//     return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
//     final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

//     return Scaffold(
//       backgroundColor: AppColors.background,

//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 height: 120,
//                 decoration: const BoxDecoration(
//                   color: AppColors.primary,
//                   borderRadius: BorderRadius.vertical(
//                     bottom: Radius.circular(30),
//                   ),
//                 ),
//               ),
//             ),
//             ListView(
//               padding: const EdgeInsets.only(top: 5),
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Foto profil di samping kiri Welcome
//                       Container(
//                         width: 60,
//                         height: 60,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                         child: _profilePhotoUrl.isNotEmpty
//                             ? ClipOval(
//                                 child: Image.network(
//                                   _profilePhotoUrl.startsWith('http')
//                                       ? _profilePhotoUrl
//                                       : 'https://appabsensi.mobileprojp.com/public/' +
//                                             _profilePhotoUrl,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) =>
//                                       const Icon(Icons.person, size: 40),
//                                 ),
//                               )
//                             : const CircleAvatar(
//                                 backgroundColor: Colors.white,
//                                 child: Icon(Icons.person, size: 30),
//                               ),
//                       ),
//                       const SizedBox(width: 15),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Welcome, $_userName',
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(height: 5),
//                             // Lokasi dipindahkan di bawah Welcome
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.location_on,
//                                   color: Colors.white,
//                                   size: 16,
//                                 ),
//                                 const SizedBox(width: 5),
//                                 Expanded(
//                                   child: Text(
//                                     _location,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 14,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 _buildMainActionCard(hasCheckedIn, hasCheckedOut),
//                 const SizedBox(height: 20),
//                 _buildAttendanceSummary(),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMainActionCard(bool hasCheckedIn, bool hasCheckedOut) {
//     return Card(
//       color: AppColors.background,
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       elevation: 6,
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       // Handle Home button press - This might be for a specific location type
//                       // For now, it's a placeholder.
//                     },
//                     icon: const Icon(Icons.home, color: AppColors.primary),
//                     label: const Text(
//                       'Home',
//                       style: TextStyle(color: AppColors.primary),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: AppColors.primary),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       backgroundColor: AppColors.primary.withOpacity(0.1),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       // Handle Office button press - This might be for a specific location type
//                       // For now, it's a placeholder.
//                     },
//                     icon: const Icon(Icons.business, color: Colors.grey),
//                     label: const Text(
//                       'Maps',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: Colors.grey),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade100,
//                   borderRadius: BorderRadius.circular(5),
//                 ),
//                 child: const Text(
//                   'GENERAL SHIFT', // This seems static, keep as is
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20), // Add spacing before the map
//             // --- START: Google Map Widget ---
//             if (_permissionGranted && _initialCameraPosition != null)
//               Container(
//                 height: 200, // Set a fixed height for the map
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: AppColors.textLight, width: 1),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: GoogleMap(
//                     onMapCreated: _onMapCreated,
//                     initialCameraPosition: CameraPosition(
//                       target: _initialCameraPosition!,
//                       zoom: 15,
//                     ),
//                     markers: _markers,
//                     myLocationEnabled: true, // Show user's current location dot
//                     myLocationButtonEnabled: true, // Show button to recenter
//                     zoomControlsEnabled: false, // Hide default zoom controls
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 height: 200,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: AppColors.textLight, width: 1),
//                 ),
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.map_outlined,
//                         size: 50,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         _location, // Display current location status
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontSize: 14,
//                         ),
//                       ),
//                       if (!_permissionGranted) // Offer to re-check permissions
//                         Padding(
//                           padding: const EdgeInsets.only(top: 10.0),
//                           child: ElevatedButton(
//                             onPressed: _determinePosition,
//                             child: const Text('Retry Location'),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),

//             // --- END: Google Map Widget ---
//             const SizedBox(height: 20), // Add spacing after the map
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _currentTime,
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.textDark,
//                       ),
//                     ),
//                     Text(
//                       _currentDate,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: AppColors.textLight,
//                       ),
//                     ),
//                   ],
//                 ),
//                 ElevatedButton(
//                   onPressed: _isCheckingInOrOut
//                       ? null // Disable button if an operation is in progress
//                       : (hasCheckedIn
//                             ? (hasCheckedOut ? null : _handleCheckOut)
//                             : _handleCheckIn),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: hasCheckedIn
//                         ? (hasCheckedOut ? Colors.grey : Colors.redAccent)
//                         : AppColors.primary,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 25,
//                       vertical: 15,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 3,
//                   ),
//                   child: _isCheckingInOrOut
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : Text(
//                           hasCheckedIn
//                               ? (hasCheckedOut ? 'Checked Out' : 'Check Out')
//                               : 'Check In',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),
//             const Divider(color: Colors.grey),
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildTimeDetail(
//                   Icons.watch_later_outlined,
//                   // Safely access jamMasuk and format it, provide 'N/A' if null
//                   _todayAbsence?.jamMasuk?.toLocal().toString().substring(
//                         11,
//                         19,
//                       ) ??
//                       'N/A',
//                   'Check In',
//                   AppColors.primary,
//                 ),
//                 _buildTimeDetail(
//                   Icons.watch_later_outlined,
//                   // Safely access jamKeluar and format it, provide 'N/A' if null
//                   _todayAbsence?.jamKeluar?.toLocal().toString().substring(
//                         11,
//                         19,
//                       ) ??
//                       'N/A',
//                   'Check Out',
//                   Colors.redAccent,
//                 ),
//                 _buildTimeDetail(
//                   Icons.watch_later_outlined,
//                   _calculateWorkingHours(),
//                   'Working HR\'s',
//                   Colors.orange,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTimeDetail(
//     IconData icon,
//     String time,
//     String label,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 28),
//         const SizedBox(height: 5),
//         Text(
//           time,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: AppColors.textDark,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12, color: AppColors.textLight),
//         ),
//       ],
//     );
//   }

//   Widget _buildAttendanceSummary() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Attendance for this Month',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.textDark,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 child: Row(
//                   children: [
//                     Text(
//                       DateFormat('MMM').format(DateTime.now()).toUpperCase(),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.textDark,
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     const Icon(
//                       Icons.calendar_today,
//                       size: 16,
//                       color: AppColors.textDark,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 15),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             children: [
//               _buildSummaryCard(
//                 'Present',
//                 _absenceStats?.totalMasuk ?? 0,
//                 Colors.green,
//               ),
//               const SizedBox(width: 10),
//               _buildSummaryCard(
//                 'Absents',
//                 _absenceStats?.totalIzin ?? 0,
//                 Colors.red,
//               ), // Assuming 'total_izin' maps to absents/leaves
//               const SizedBox(width: 10),
//               _buildSummaryCard(
//                 'Total',
//                 _absenceStats?.totalAbsen ?? 0,
//                 Colors.orange,
//               ), // Assuming 'total_absen' maps to late/other
//             ],
//           ),
//         ),
//       ],
//     );
//     //////addd
//   }

//   Widget _buildSummaryCard(String title, int count, Color color) {
//     return Expanded(
//       child: Card(
//         color: AppColors.background,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         elevation: 2,
//         child: Column(
//           children: [
//             Container(
//               height: 5.0,
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(10),
//                   topRight: Radius.circular(10),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       color: Colors.black87,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Align(
//                     alignment: Alignment.bottomRight,
//                     child: Text(
//                       count.toString().padLeft(2, '0'),
//                       style: TextStyle(
//                         color: color,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 32,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
