import 'package:amar_uddokta/madmin/widgets/label_service.dart';

// Import Material for Widget

class OrderModel {
  final String orderId;
  final String userName;
  final String userPhone;
  final Map<String, dynamic> location;
  final String? userGpsLocation; // ✅ Added userGpsLocation field
  final List<dynamic> items;
  final double total;
  final double deliveryCharge;
  final double grandTotal;
  final String paymentMethod;
  final String trxId;
  final String userPaymentNumber;
  String status;
  String paymentStatus;
  final DateTime placedAt; // শুধু placedAt ব্যবহার করা হচ্ছে
  String? cancelledBy;
  DateTime? cancelledAt;
  String? userId;
  String? specialMessage; // Added special message field

  OrderModel({
    required this.orderId,
    required this.userName,
    required this.userPhone,
    required this.location,
    this.userGpsLocation, // ✅ Added userGpsLocation to constructor
    required this.items,
    required this.total,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.paymentMethod,
    required this.trxId,
    required this.userPaymentNumber,
    required this.status,
    required this.paymentStatus,
    required this.placedAt,
    this.cancelledBy,
    this.cancelledAt,
    this.userId,
    this.specialMessage, // Added special message parameter
  });

  factory OrderModel.fromMap(Map<String, dynamic> data) {
    try {
      // শুধু placedAt ফিল্ড থেকে ডেটা নেওয়া হচ্ছে
      DateTime? timestamp;
      if (data['placedAt'] != null) {
        // Assuming Supabase returns DateTime directly or a compatible type
        timestamp = data['placedAt'] as DateTime?;
      }

      // লোকেশন ফিল্ড হ্যান্ডলিং
      Map<String, dynamic> locationData = {};
      if (data['location'] != null) {
        locationData = Map<String, dynamic>.from(data['location']);
      }

      // userGpsLocation ফিল্ড হ্যান্ডলিং
      String? userGpsLocationData;
      if (data['userGpsLocation'] != null) {
        userGpsLocationData = data['userGpsLocation'] as String?;
      }

      return OrderModel(
        orderId: data['orderId'] ?? '',
        userName: data['userName'] ?? '',
        userPhone: data['userPhone'] ?? '',
        location: locationData,
        userGpsLocation: userGpsLocationData, // ✅ Assigned userGpsLocation
        items: List<dynamic>.from(data['items'] ?? []),
        total: (data['total'] as num?)?.toDouble() ?? 0.0,
        deliveryCharge: (data['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
        grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: data['paymentMethod'] ?? '',
        trxId: data['trxId'] ?? '',
        userPaymentNumber: data['userPaymentNumber'] ?? '',
        status: data['status'] ?? 'pending',
        paymentStatus: data['paymentStatus'] ?? 'pending',
        placedAt: timestamp ?? DateTime.now(),
        cancelledBy: data['cancelledBy'],
        cancelledAt: data['cancelledAt']
            as DateTime?, // Assuming Supabase returns DateTime directly
        userId: data['userId'],
        specialMessage:
            data['specialMessage'], // Added special message from data
      );
    } catch (e, stacktrace) {
      print('Error parsing OrderModel from map: $e');
      print('Data: $data');
      print('Stacktrace: $stacktrace');
      // Re-throw the error to be caught by the OrderController's onError
      rethrow;
    }
  }

  // Added getStatusText method
  String getStatusText(LabelService labelService) {
    switch (status) {
      case 'pending':
        return labelService.getLabel('pending') ?? 'Pending';
      case 'shipped':
        return labelService.getLabel('shipped') ?? 'Shipped';
      case 'delivered':
        return labelService.getLabel('delivered') ?? 'Delivered';
      case 'cancelled':
        return labelService.getLabel('cancelled') ?? 'Cancelled';
      default:
        return labelService.getLabel('unknown') ?? 'Unknown Status';
    }
  }
}
