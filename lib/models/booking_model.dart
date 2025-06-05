class BookingModel {
  final String id;
  final String passengerEmail;
  final String pickupLocation;
  final String destination;
  final DateTime scheduledDateTime;
  final double distance;
  final double price;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final DateTime createdAt;
  String? driverEmail;

  BookingModel({
    required this.id,
    required this.passengerEmail,
    required this.pickupLocation,
    required this.destination,
    required this.scheduledDateTime,
    required this.distance,
    required this.price,
    required this.status,
    required this.createdAt,
    this.driverEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerEmail': passengerEmail,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'distance': distance,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'driverEmail': driverEmail,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      passengerEmail: map['passengerEmail'] as String,
      pickupLocation: map['pickupLocation'] as String,
      destination: map['destination'] as String,
      scheduledDateTime: DateTime.parse(map['scheduledDateTime'] as String),
      distance: map['distance'] as double,
      price: map['price'] as double,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      driverEmail: map['driverEmail'] as String?,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel.fromMap(json);
} 