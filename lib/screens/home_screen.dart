import 'dart:async';
import 'package:absensi_project/constants/app_colors.dart';
import 'package:absensi_project/models/app_model.dart';
import 'package:absensi_project/screens/main_bottom_navigator_bar.dart';
import 'package:absensi_project/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;
  const HomeScreen({super.key, required this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String _userName = 'User';
  String _location = 'Getting Location...';
  String _currentDate = '';
  String _currentTime = '';
  String _profilePhotoUrl = '';
  Timer? _timer;

  AbsenceToday? _todayAbsence;
  AbsenceStats? _absenceStats;

  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _isCheckingInOrOut = false;

  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> get _markers => <gmaps.Marker>{};
  gmaps.LatLng? _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _initData();
    widget.refreshNotifier.addListener(_handleRefreshSignal);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _updateDateTime();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  Future<void> _initData() async {
    await _determinePosition();
    await _loadUserData();
    await _fetchAttendanceData();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _initData();
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _onPullToRefresh() async {
    await _initData();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data refreshed!')));
    }
  }

  Future<void> _loadUserData() async {
    final ApiResponse<User> response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _userName = response.data!.name;
        _profilePhotoUrl = response.data!.profile_photo ?? '';
      });
    } else {
      setState(() {
        _userName = 'User';
        _profilePhotoUrl = '';
      });
    }
  }

  void _updateDateTime() {
    _currentDate = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());
    _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showErrorDialog('Location services are disabled. Please enable them.');
      }
      setState(() {
        _location = 'Location services disabled';
        _permissionGranted = false;
        _currentPosition = null;
        _initialCameraPosition = null;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showErrorDialog(
            'Location permissions are denied. Please grant them in settings.',
          );
        }
        setState(() {
          _location = 'Location permissions denied';
          _permissionGranted = false;
          _currentPosition = null;
          _initialCameraPosition = null;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
      setState(() {
        _location = 'Location permissions permanently denied';
        _permissionGranted = false;
        _currentPosition = null;
        _initialCameraPosition = null;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _currentPosition = position;
        _permissionGranted = true;
        _initialCameraPosition = gmaps.LatLng(
          position.latitude,
          position.longitude,
        );
        _markers.clear();
        _addMarker(
          gmaps.LatLng(position.latitude, position.longitude),
          'current_location',
          'Your Current Location',
        );
      });
      if (_mapController != null && _initialCameraPosition != null) {
        _mapController?.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(_initialCameraPosition!, 15),
        );
      }
      await _getAddressFromLatLng(position);
    } on TimeoutException {
      if (mounted) {
        _showErrorDialog(
          'Failed to get current location: Location request timed out.',
        );
      }
      setState(() {
        _location = 'Location timeout, try again';
        _permissionGranted = false;
        _currentPosition = null;
        _initialCameraPosition = null;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to get current location: $e');
      }
      setState(() {
        _location = 'Failed to get location';
        _permissionGranted = false;
        _currentPosition = null;
        _initialCameraPosition = null;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        _location =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _location = 'Address not found';
      });
    }
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
    if (_initialCameraPosition != null) {
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_initialCameraPosition!, 15),
      );
    }
  }

  void _addMarker(gmaps.LatLng position, String markerId, String title) {
    setState(() {
      _markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(markerId),
          position: position,
          infoWindow: gmaps.InfoWindow(title: title),
        ),
      );
    });
  }

  Future<void> _fetchAttendanceData() async {
    final ApiResponse<AbsenceToday> todayAbsenceResponse = await _apiService
        .getAbsenceToday();
    if (todayAbsenceResponse.statusCode == 200 &&
        todayAbsenceResponse.data != null) {
      setState(() {
        _todayAbsence = todayAbsenceResponse.data;
      });
    } else {
      setState(() {
        _todayAbsence = null;
      });
    }

    final String currentMonthStart = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(DateTime.now().year, DateTime.now().month, 1));
    final String currentMonthEnd = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(DateTime.now().year, DateTime.now().month + 1, 0));

    final ApiResponse<AbsenceStats> statsResponse = await _apiService
        .getAbsenceStats(
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
        );

    if (statsResponse.statusCode == 200 && statsResponse.data != null) {
      setState(() {
        _absenceStats = statsResponse.data;
      });
    } else {
      setState(() {
        _absenceStats = null;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition();
      if (_currentPosition == null) return;
    }
    if (_isCheckingInOrOut) return;

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final String formattedCheckInTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkIn(
        checkInLat: _currentPosition!.latitude,
        checkInLng: _currentPosition!.longitude,
        checkInAddress: _location,
        status: 'masuk',
        attendanceDate: formattedAttendanceDate,
        checkInTime: formattedCheckInTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        await _fetchAttendanceData();
        MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showErrorDialog('Check In Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-in: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition();
      if (_currentPosition == null) return;
    }
    if (_isCheckingInOrOut) return;

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      final String formattedCheckOutTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkOut(
        checkOutLat: _currentPosition!.latitude,
        checkOutLng: _currentPosition!.longitude,
        checkOutAddress: _location,
        attendanceDate: formattedAttendanceDate,
        checkOutTime: formattedCheckOutTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        await _fetchAttendanceData();
        MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showErrorDialog('Check Out Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-out: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String _calculateWorkingHours() {
    if (_todayAbsence == null || _todayAbsence!.jamMasuk == null) {
      return '00:00:00';
    }

    final DateTime checkInDateTime = _todayAbsence!.jamMasuk!;
    Duration duration;

    if (_todayAbsence!.jamKeluar != null) {
      duration = _todayAbsence!.jamKeluar!.difference(checkInDateTime);
    } else {
      duration = DateTime.now().difference(checkInDateTime);
    }

    if (duration.isNegative) {
      return '00:00:00';
    }

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMainActionCard(bool hasCheckedIn, bool hasCheckedOut) {
    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Lottie Animation on the left with text
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/working.json',
                  height: 170,
                  width: 170,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'YOUR TIME\nOUR PIORITY',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_permissionGranted && _initialCameraPosition != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: gmaps.GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: gmaps.CameraPosition(
                      target: _initialCameraPosition!,
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 50,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _location,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      if (!_permissionGranted)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: ElevatedButton(
                            onPressed: _determinePosition,
                            child: const Text('Retry Location'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      _currentDate,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: ElevatedButton(
                      onPressed: _isCheckingInOrOut
                          ? null
                          : (hasCheckedIn
                                ? (hasCheckedOut ? null : _handleCheckOut)
                                : _handleCheckIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCheckedIn
                            ? (hasCheckedOut
                                  ? AppColors.textLight
                                  : AppColors.error)
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: _isCheckingInOrOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                hasCheckedIn
                                    ? (hasCheckedOut
                                          ? 'Checked Out'
                                          : 'Check Out')
                                    : 'Check In',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeDetail(
                  FaIcon(
                    FontAwesomeIcons.arrowRightFromBracket,
                    color: AppColors.present,
                  ),
                  _todayAbsence?.jamMasuk?.toLocal().toString().substring(
                        11,
                        19,
                      ) ??
                      'N/A',
                  'Check In',
                  AppColors.primary,
                ),
                _buildTimeDetail(
                  FaIcon(FontAwesomeIcons.personHiking, color: AppColors.error),
                  _todayAbsence?.jamKeluar?.toLocal().toString().substring(
                        11,
                        19,
                      ) ??
                      'N/A',
                  'Check Out',
                  AppColors.error,
                ),
                _buildTimeDetail(
                  FaIcon(FontAwesomeIcons.check, color: AppColors.error),
                  _calculateWorkingHours(),
                  'Working HR\'s',
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDetail(
    FaIcon iconCustom,
    String time,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        FaIcon(iconCustom.icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance for this Month',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat(
                        'MMM',
                        'id_ID',
                      ).format(DateTime.now()).toUpperCase(),
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
            ],
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildSummaryCard(
                'Present',
                _absenceStats?.totalMasuk ?? 0,
                AppColors.present,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                'Absents',
                _absenceStats?.totalIzin ?? 0,
                AppColors.absent,
                Icons.cancel_outlined,
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                'Total',
                _absenceStats?.totalAbsen ?? 0,
                AppColors.total,
                Icons.calendar_month,
              ),
            ],
          ),
        ),
        // Copyright text added here
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Center(
            child: Opacity(
              opacity: 0.6,
              child: Text(
                '© Rida_AttendlyApps',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.3),
                  size: 40,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  count.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _onPullToRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.only(top: 5),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _profilePhotoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profilePhotoUrl.startsWith('http')
                                        ? _profilePhotoUrl
                                        : 'https://appabsensi.mobileprojp.com/public/' +
                                              _profilePhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: AppColors.textLight,
                                            ),
                                  ),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, $_userName',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainActionCard(hasCheckedIn, hasCheckedOut),
                  const SizedBox(height: 20),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 20),
                  _buildAttendanceSummary(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
