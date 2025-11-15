// lib/models/order_model.dart

import 'package:amar_uddokta/uddoktaa/widgets/label_service.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final String userPhone;
  final Map<String, dynamic> location;
  final String? userGpsLocation;
  final String? specialMessage;
  final List<Map<String, dynamic>> items;
  final double total;
  final double deliveryCharge;
  final double grandTotal;
  final String paymentMethod;
  final String paymentStatus;
  final String trxId;
  final String userPaymentNumber;
  final String status;
  final DateTime placedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? referCode;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.location,
    this.userGpsLocation,
    this.specialMessage,
    required this.items,
    required this.total,
    required this.deliveryCharge,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.trxId,
    required this.userPaymentNumber,
    required this.status,
    required this.placedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.referCode,
  });

  // এই ফ্যাক্টরি কনস্ট্রাক্টরটিই Supabase থেকে আসা JSON ডেটাকে OrderModel-এ রূপান্তরিত করে
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      location: json['location'] ?? {},
      userGpsLocation: json['user_gps_location'],
      specialMessage: json['special_message'],
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      trxId: json['trx_id'] ?? '',
      userPaymentNumber: json['user_payment_number'] ?? '',
      status: json['status'] ?? '',
      placedAt: DateTime.parse(json['placed_at']),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      cancelledBy: json['cancelled_by'],
      referCode: json['refer_code'],
    );
  }

  // Supabase থেকে প্রাপ্ত ডেটা থেকে OrderModel অবজেক্ট তৈরি করে
  factory OrderModel.fromSupabase(Map<String, dynamic> data) {
    return OrderModel(
      orderId: data['order_id'] as String,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String,
      userPhone: data['user_phone'] as String,
      location: data['location'] ?? {},
      userGpsLocation: data['user_gps_location'],
      specialMessage: data['special_message'],
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (data['delivery_charge'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['payment_method'] ?? '',
      paymentStatus: data['payment_status'] ?? '',
      trxId: data['trx_id'] ?? '',
      userPaymentNumber: data['user_payment_number'] ?? '',
      status: data['status'] ?? '',
      placedAt: DateTime.parse(data['placed_at']),
      cancelledAt: data['cancelled_at'] != null
          ? DateTime.parse(data['cancelled_at'])
          : null,
      cancelledBy: data['cancelled_by'],
      referCode: data['refer_code'],
    );
  }

  // অবজেক্টটিকে Supabase ডাটাবেসে পাঠানোর জন্য একটি JSON ম্যাপে রূপান্তরিত করে।
  Map<String, dynamic> toSupabaseJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'location': location,
      'user_gps_location': userGpsLocation,
      'special_message': specialMessage,
      'items': items,
      'total': total,
      'delivery_charge': deliveryCharge,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'trx_id': trxId,
      'user_payment_number': userPaymentNumber,
      'status': status,
      'placed_at': placedAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancelled_by': cancelledBy,
      'refer_code': referCode,
    };
  }

  // স্ট্যাটাস টেক পেতে হেল্পার মেথড
  String getStatusText(LabelService labelService) {
    final statusOptions =
        labelService.labels?['statusOptions'] as Map<String, dynamic>?;
    return statusOptions?[status] ?? status;
  }

  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? userName,
    String? userPhone,
    Map<String, dynamic>? location,
    String? userGpsLocation,
    String? specialMessage,
    List<Map<String, dynamic>>? items,
    double? total,
    double? deliveryCharge,
    double? grandTotal,
    String? paymentMethod,
    String? paymentStatus,
    String? trxId,
    String? userPaymentNumber,
    String? status,
    DateTime? placedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? referCode,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      location: location ?? this.location,
      userGpsLocation: userGpsLocation ?? this.userGpsLocation,
      specialMessage: specialMessage ?? this.specialMessage,
      items: items ?? this.items,
      total: total ?? this.total,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      trxId: trxId ?? this.trxId,
      userPaymentNumber: userPaymentNumber ?? this.userPaymentNumber,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      referCode: referCode ?? this.referCode,
    );
  }
}
