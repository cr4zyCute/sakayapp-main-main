import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String usersCollection = 'users';
  final String bookingsCollection = 'bookings';

  // Hash password (Never store plain text passwords!)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Register a new user
  Future<bool> registerUser(UserModel user) async {
    try {
      // Check if user already exists
      final userDoc = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: user.email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        return false; // User already exists
      }

      // Hash the password before storing
      final hashedPassword = _hashPassword(user.password);

      // Create new user document
      await _firestore.collection(usersCollection).add({
        'email': user.email,
        'password': hashedPassword,
        'role': user.role,
        'name': user.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Add driver details
  Future<bool> addDriverDetails(String email, String plateNumber) async {
    try {
      await _firestore.collection('driver_details').add({
        'email': email,
        'plateNumber': plateNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding driver details: $e');
      return false;
    }
  }

  // Get driver details
  Future<Map<String, dynamic>?> getDriverDetails(String email) async {
    try {
      final snapshot = await _firestore
          .collection('driver_details')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.data();
    } catch (e) {
      print('Error getting driver details: $e');
      return null;
    }
  }

  // Login user
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      final userDoc = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: hashedPassword)
          .get();

      if (userDoc.docs.isEmpty) {
        return null; // User not found or invalid credentials
      }

      final userData = userDoc.docs.first.data();
      return UserModel(
        email: userData['email'] as String,
        password: '', // Don't include password in the model
        role: userData['role'] as String,
        name: userData['name'] as String,
        createdAt: (userData['createdAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      print('Attempting to fetch user with email: $email'); // Debug log
      
      final userDoc = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .get();

      print('Query completed. Found ${userDoc.docs.length} documents'); // Debug log

      if (userDoc.docs.isEmpty) {
        print('No user found with email: $email'); // Debug log
        return null;
      }

      final userData = userDoc.docs.first.data();
      print('User data retrieved: ${userData.toString()}'); // Debug log

      // Check if all required fields are present
      if (!userData.containsKey('email') || 
          !userData.containsKey('role') || 
          !userData.containsKey('name')) {
        print('Missing required fields in user data'); // Debug log
        return null;
      }

      final userModel = UserModel(
        email: userData['email'] as String,
        password: '', // Don't include password
        role: userData['role'] as String,
        name: userData['name'] as String,
        createdAt: userData['createdAt'] != null 
            ? (userData['createdAt'] as Timestamp).toDate()
            : null,
      );

      print('Successfully created UserModel object'); // Debug log
      return userModel;
    } catch (e, stackTrace) {
      print('Error getting user: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log for more detail
      return null;
    }
  }

  // Update user
  Future<bool> updateUser(String email, Map<String, dynamic> data) async {
    try {
      final userDoc = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isEmpty) {
        return false;
      }

      await userDoc.docs.first.reference.update(data);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String email) async {
    try {
      final userDoc = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isEmpty) {
        return false;
      }

      await userDoc.docs.first.reference.delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Create a new booking
  Future<String?> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore.collection(bookingsCollection).add(booking.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  // Get bookings for a passenger
  Stream<List<BookingModel>> getPassengerBookings(String passengerEmail) {
    return _firestore
        .collection(bookingsCollection)
        .where('passengerEmail', isEqualTo: passengerEmail)
        // Temporarily removing orderBy clauses until index is created
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Sort in memory instead
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  // Get available bookings for drivers
  Stream<List<BookingModel>> getAvailableBookings() {
    return _firestore
        .collection(bookingsCollection)
        .where('status', isEqualTo: 'pending')
        // Temporarily removing orderBy clauses until index is created
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Sort in memory instead
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  // Get bookings assigned to a driver
  Stream<List<BookingModel>> getDriverBookings(String driverEmail) {
    return _firestore
        .collection(bookingsCollection)
        .where('driverEmail', isEqualTo: driverEmail)
        // Temporarily removing orderBy clauses until index is created
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Sort in memory instead
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status, {String? driverEmail}) async {
    try {
      final data = {'status': status};
      if (driverEmail != null) {
        data['driverEmail'] = driverEmail;
      }
      
      await _firestore
          .collection(bookingsCollection)
          .doc(bookingId)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Delete booking
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _firestore
          .collection(bookingsCollection)
          .doc(bookingId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting booking: $e');
      return false;
    }
  }

  // Update driver location
  Future<bool> updateDriverLocation(String driverEmail, double latitude, double longitude) async {
    try {
      await _firestore.collection('driver_locations').doc(driverEmail).set({
        'email': driverEmail,
        'latitude': latitude,
        'longitude': longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating driver location: $e');
      return false;
    }
  }

  // Get driver location
  Stream<Map<String, dynamic>?> getDriverLocation(String driverEmail) {
    return _firestore
        .collection('driver_locations')
        .doc(driverEmail)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
} 