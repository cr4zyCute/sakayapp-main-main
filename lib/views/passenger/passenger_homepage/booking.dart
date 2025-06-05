import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show min;
import 'map_selection_page.dart';
import '../../../services/firestore_service.dart';
import '../../../models/booking_model.dart';

class BookingPage extends StatefulWidget {
  final String userEmail;

  const BookingPage({
    super.key,
    required this.userEmail,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoadingLocation = false;
  double _distance = 0.0;
  double _price = 0.0;
  bool _showPickupError = false;
  bool _showDestinationError = false;
  bool _showDateTimeError = false;

  double _calculatePrice(double distanceKm) {
    // First kilometer: ₱20
    double price = 20.0;
    double remainingDistance = distanceKm - 1;

    if (remainingDistance <= 0) {
      return price;
    }

    // Additional fare up to 8 km: ₱16/km
    double upToEightKm =
        min(remainingDistance, 7); // 7 because we already counted first km
    price += upToEightKm * 16;
    remainingDistance -= upToEightKm;

    if (remainingDistance <= 0) {
      return price;
    }

    // Additional fare from 8 km above: ₱20/km
    price += remainingDistance * 20;

    return price;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition();

      // Reverse geocode the location
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pickupController.text = data['display_name'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _selectDestinationOnMap() async {
    try {
      // Get current location first
      final Position position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapSelectionPage(
            initialLocation: currentLocation,
            showCurrentLocation: true,
          ),
        ),
      );

      if (result != null) {
        setState(() {
          _destinationController.text = result['address'];
          _distance = result['distance'] ?? 0.0;
          _price = _calculatePrice(_distance);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveBooking() async {
    setState(() {
      _showPickupError = _pickupController.text.isEmpty;
      _showDestinationError = _destinationController.text.isEmpty;
      _showDateTimeError = _selectedDateTime == null;
    });

    if (_pickupController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    try {
      final firestoreService = FirestoreService();

      final booking = BookingModel(
        id: '', // Will be set by Firestore
        passengerEmail: widget.userEmail,
        pickupLocation: _pickupController.text,
        destination: _destinationController.text,
        scheduledDateTime: _selectedDateTime!,
        distance: _distance,
        price: _price,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final bookingId = await firestoreService.createBooking(booking);

      if (bookingId != null) {
        // Show confirmation message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking Confirmed!')),
          );
          // Navigate back to home page
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to create booking. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
      }
    }
  }

  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 3) return [];

    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?format=json&q=$pattern&limit=5'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((place) => place['display_name'] as String).toList();
      }
    } catch (e) {
      print('Error getting suggestions: $e');
    }
    return [];
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Widget _buildPickupField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pickup Location",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                labelText: 'Enter pickup location',
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: _showPickupError ? Colors.red : Colors.blueAccent,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: _showPickupError ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                suffixIcon: IconButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.blueAccent),
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  tooltip: 'Use current location',
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Destination",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 3) {
              return const Iterable<String>.empty();
            }
            final suggestions = await _getSuggestions(textEditingValue.text);
            return suggestions;
          },
          onSelected: (String selection) {
            setState(() {
              _destinationController.text = selection;
              _showDestinationError = false;
            });
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController controller,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Enter Destination',
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color:
                        _showDestinationError ? Colors.red : Colors.blueAccent,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color:
                        _showDestinationError ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  onPressed: _selectDestinationOnMap,
                  tooltip: 'Select on map',
                ),
              ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(
                          option,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Your Ride',
          style: TextStyle(
            color: Color.fromARGB(255, 35, 35, 35),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 3,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPickupField(),
              const SizedBox(height: 24),
              _buildDestinationField(),
              if (_distance > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.blueAccent.withOpacity(0.7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Distance:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Price:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '₱${_price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                "Schedule Date & Time",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _showDateTimeError
                          ? Colors.red
                          : Colors.blueAccent.withOpacity(0.7),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDateTime == null
                            ? 'Select date & time'
                            : '${_selectedDateTime!.toLocal()}'.split('.')[0],
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDateTime == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      const Icon(Icons.calendar_today,
                          color: Colors.blueAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedDateTime = DateTime.now();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Book Now',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
