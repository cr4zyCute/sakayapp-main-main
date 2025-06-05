import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../models/booking_model.dart';

class MyBookingPage extends StatefulWidget {
  final String userEmail;
  
  const MyBookingPage({
    super.key,
    required this.userEmail,
  });

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _firestoreService.getPassengerBookings(widget.userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text('No bookings found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  title: Text(
                    '${booking.pickupLocation} → ${booking.destination}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Date: ${booking.scheduledDateTime.toString().split('.')[0]}'),
                      Text('Status: ${booking.status}'),
                      Text('Price: ₱${booking.price.toStringAsFixed(2)}'),
                      if (booking.driverEmail != null)
                        Text('Driver: ${booking.driverEmail}'),
                    ],
                  ),
                  trailing: _buildStatusIcon(booking.status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;

    switch (status.toLowerCase()) {
      case 'completed':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'cancelled':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'accepted':
        iconData = Icons.directions_car;
        iconColor = Colors.blue;
        break;
      case 'pending':
      default:
        iconData = Icons.schedule;
        iconColor = Colors.orange;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 30,
    );
  }
}
