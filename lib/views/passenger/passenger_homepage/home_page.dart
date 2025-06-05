import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/firestore_service.dart';
import 'booking.dart'; // Adjust path as necessary
import 'profile_page.dart';
import 'my_booking_page.dart';
import 'settings_page.dart';

import '../../login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//import 'package:sakayna/views/login.dart';

class Passenger_HomePage extends StatefulWidget {
  final String userEmail;

  const Passenger_HomePage({
    super.key,
    required this.userEmail,
  });

  @override
  State<Passenger_HomePage> createState() => _Passenger_HomePageState();
}

class _Passenger_HomePageState extends State<Passenger_HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;
  final int _selectedIndex = 0;
  final _firestoreService = FirestoreService();
  final Map<String, LatLng> _driverLocations = {};

  static const String GRAPHOPPER_API_KEY =
      'b03a319d-d14e-4d65-bf0a-e6e1e8a253dd'; // Replace with your actual API key

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _listenToDriverLocations();
    // Show greeting popup after a short delay to ensure the page is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _showGreetingDialog();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  void _listenToDriverLocations() {
    FirebaseFirestore.instance
        .collection('driver_locations')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _driverLocations.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['latitude'] != null && data['longitude'] != null) {
            _driverLocations[doc.id] = LatLng(
              data['latitude'] as double,
              data['longitude'] as double,
            );
          }
        }
      });
    });
  }

  Future<void> _getRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://graphhopper.com/api/1/route'
      '?point=${from.latitude},${from.longitude}'
      '&point=${to.latitude},${to.longitude}'
      '&vehicle=car'
      '&points_encoded=false'
      '&key=$GRAPHOPPER_API_KEY',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['paths'][0]['points']['coordinates'] as List;

      setState(() {
        _routePoints =
            coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
      });
    } else {
      print('Route fetch failed: ${response.body}');
    }
  }

  void _onMapTap(LatLng latlng) {
    setState(() {
      _destination = latlng;
      _routePoints = [];
    });

    if (_currentLocation != null) {
      _getRoute(_currentLocation!, latlng);
    }
  }

  void _showGreetingDialog() {
    final now = DateTime.now();
    String greeting;
    if (now.hour < 12) {
      greeting = 'Good Morning';
    } else if (now.hour < 18) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[now.weekday - 1];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Image that overflows at the top
              Positioned(
                top: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/images/greetings-preview.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Main content
              Container(
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back, ${widget.userEmail.split('@')[0]}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Have a Good $dayName',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Sakay Na'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation!,
                    initialZoom: 15,
                    onTap: (tapPosition, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Current location marker
                        Marker(
                          point: _currentLocation!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        // Destination marker
                        if (_destination != null)
                          Marker(
                            point: _destination!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        // Driver markers
                        ..._driverLocations.entries.map(
                          (entry) => Marker(
                            point: entry.value,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.motorcycle,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4,
                            color: Colors.green,
                          ),
                        ],
                      ),
                  ],
                ),
                // Book Now Button
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPage(
                                userEmail: widget.userEmail,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Book now",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.blue[300],
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/riderbg.png'),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.userEmail.split('@')[0],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                    "🚖 Passenger"), // Role is always passenger in this context
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text("Profile", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.white),
            title:
                const Text("My Booking", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MyBookingPage(userEmail: widget.userEmail)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title:
                const Text("Settings", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Clear stored credentials
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Center(
                child: Text(
                  "Log out",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    // Implementation of _buildBottomNavigationBar method
    // This is a placeholder and should be implemented
    return Container();
  }
}
