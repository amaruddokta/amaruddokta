class User {
  final String id;
  final String name;
  final String email; // ইমেল ফিল্ড যোগ করা হয়েছে
  final String phone;
  final String password;
  final String division;
  final String district;
  final String upazila;
  final String? union; // ইউনিয়ন ফিল্ড যোগ করা হয়েছে
  final String village;
  final String? ward; // ওয়ার্ড ফিল্ড যোগ করা হয়েছে
  final String? house; // হাউস ফিল্ড যোগ করা হয়েছে
  final String? road; // রোড ফিল্ড যোগ করা হয়েছে
  final String? imageUrl;
  final String? referCode; // রেফারেল কোড ফিল্ড যোগ করা হয়েছে
  final double? referBalance; // রেফারেল ব্যালেন্স ফিল্ড যোগ করা হয়েছে
  final double? lat;
  final double? lng;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email, // ইমেল ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    required this.phone,
    required this.password,
    required this.division,
    required this.district,
    required this.upazila,
    this.union, // ইউনিয়ন ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    required this.village,
    this.ward, // ওয়ার্ড ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    this.house, // হাউস ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    this.road, // রোড ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    this.imageUrl,
    this.referCode, // রেফারেল কোড ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    this.referBalance, // রেফারেল ব্যালেন্স ফিল্ড কনস্ট্রাক্টরে যোগ করা হয়েছে
    this.lat,
    this.lng,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email, // ইমেল ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "phone": phone,
      "password": password,
      "division": division,
      "district": district,
      "upazila": upazila,
      "union": union, // ইউনিয়ন ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "village": village,
      "ward": ward, // ওয়ার্ড ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "house": house, // হাউস ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "road": road, // রোড ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "imageUrl": imageUrl,
      "refer_code": referCode, // রেফারেল কোড ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "refer_balance":
          referBalance, // রেফারেল ব্যালেন্স ফিল্ড toJson মেথডে যোগ করা হয়েছে
      "location_lat": lat,
      "location_lng": lng,
      "created_at": createdAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      email: json["email"] ?? "", // ইমেল ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      phone: json["phone"] ?? "",
      password: json["password"] ?? "",
      division: json["division"] ?? "",
      district: json["district"] ?? "",
      upazila: json["upazila"] ?? "",
      union: json["union"], // ইউনিয়ন ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      village: json["village"] ?? "",
      ward: json["ward"], // ওয়ার্ড ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      house: json["house"], // হাউস ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      road: json["road"], // রোড ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      imageUrl: json["imageUrl"],
      referCode:
          json["refer_code"], // রেফারেল কোড ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      referBalance: json["refer_balance"]
          ?.toDouble(), // রেফারেল ব্যালেন্স ফিল্ড fromJson মেথডে যোগ করা হয়েছে
      lat: (json["location_lat"] as num?)?.toDouble(),
      lng: (json["location_lng"] as num?)?.toDouble(),
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
    );
  }

  // কপি উইথ মেথড যোগ করা হয়েছে যা অবজেক্টের কিছু ফিল্ড আপডেট করতে সাহায্য করবে
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? division,
    String? district,
    String? upazila,
    String? union,
    String? village,
    String? ward,
    String? house,
    String? road,
    String? imageUrl,
    String? referCode,
    double? referBalance,
    double? lat,
    double? lng,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      division: division ?? this.division,
      district: district ?? this.district,
      upazila: upazila ?? this.upazila,
      union: union ?? this.union,
      village: village ?? this.village,
      ward: ward ?? this.ward,
      house: house ?? this.house,
      road: road ?? this.road,
      imageUrl: imageUrl ?? this.imageUrl,
      referCode: referCode ?? this.referCode,
      referBalance: referBalance ?? this.referBalance,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
