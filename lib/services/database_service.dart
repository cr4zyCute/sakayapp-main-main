import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class DatabaseService {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  // Register a new user
  Future<bool> registerUser(UserModel user) async {
    try {
      // Create a unique key for the user based on their email
      final userKey = user.email.replaceAll('.', '_').replaceAll('@', '_at_');
      
      // Check if user already exists
      final snapshot = await _usersRef.child(userKey).get();
      if (snapshot.exists) {
        return false; // User already exists
      }

      // Save user data
      await _usersRef.child(userKey).set(user.toJson());
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Login user
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      final userKey = email.replaceAll('.', '_').replaceAll('@', '_at_');
      final snapshot = await _usersRef.child(userKey).get();

      if (!snapshot.exists) {
        return null; // User not found
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final user = UserModel.fromJson(userData);

      // Check password (In production, use proper password hashing)
      if (user.password != password) {
        return null; // Invalid password
      }

      return user;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  // Get user data
  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        return UserModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user data
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersRef.child(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.child(uid).remove();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get all users
  Stream<List<UserModel>> getUsers() {
    return _usersRef.onValue.map((event) {
      final data = event.snapshot.value as Map<String, dynamic>;
      return data.values.map((value) => UserModel.fromJson(value as Map<String, dynamic>)).toList();
    });
  }

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _usersRef.orderByChild('role').equalTo(role).onValue.map((event) {
      final data = event.snapshot.value as Map<String, dynamic>;
      return data.values.map((value) => UserModel.fromJson(value as Map<String, dynamic>)).toList();
    });
  }
}
