import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapSelectionPage extends StatefulWidget {
  final LatLng? initialLocation;
  final bool showCurrentLocation;

  const MapSelectionPage({
    Key? key, 
    this.initialLocation,
    this.showCurrentLocation = false,
  }) : super(key: key);

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
      if (!widget.showCurrentLocation) {
        _selectedLocation = widget.initialLocation;
        _reverseGeocode(widget.initialLocation!);
      }
    }
  }

  Future<void> _getRoute() async {
    if (_currentLocation == null || _selectedLocation == null) return;

    try {
      final response = await http.get(Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${_currentLocation!.longitude},${_currentLocation!.latitude};'
          '${_selectedLocation!.longitude},${_selectedLocation!.latitude}'
          '?overview=full&geometries=geojson'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          final distance = data['routes'][0]['distance'] as num;
          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
                .toList()
                .cast<LatLng>();
            _routeDistance = distance / 1000;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting route: $e')),
      );
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() {
      _isLoading = true;
      _selectedLocation = location;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['display_name'];
        });
        // Get route after setting the selected location
        await _getRoute();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    
    // Add current location marker if available
    if (_currentLocation != null && widget.showCurrentLocation) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40.0,
          height: 40.0,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }

    // Add selected location marker if available
    if (_selectedLocation != null) {
      markers.add(
        Marker(
          point: _selectedLocation!,
          width: 40.0,
          height: 40.0,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? const LatLng(10.3157, 123.8854), // Default to Cebu City
              initialZoom: 15,
              onTap: (_, point) {
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              // Add route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: Colors.blue.withOpacity(0.8),
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const LinearProgressIndicator()
                    else
                      Column(
                        children: [
                          Text(
                            _selectedAddress,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_routeDistance > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Distance: ${_routeDistance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context, {
                            'location': _selectedLocation,
                            'address': _selectedAddress,
                            'distance': _routeDistance,
                          });
                        },
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 