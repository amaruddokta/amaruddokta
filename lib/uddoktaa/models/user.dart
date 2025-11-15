class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String division;
  final String district;
  final String upazila;
  final String? union;
  final String village;
  final String? ward;
  final String? house;
  final String? road;
  final String? imageUrl;
  final String? referCode;
  final double? referBalance;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;
  final String? status;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.division,
    required this.district,
    required this.upazila,
    this.union,
    required this.village,
    this.ward,
    this.house,
    this.road,
    this.imageUrl,
    this.referCode,
    this.referBalance,
    this.lat,
    this.lng,
    this.createdAt,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "password": password,
      "division": division,
      "district": district,
      "upazila": upazila,
      "union": union,
      "village": village,
      "ward": ward,
      "house": house,
      "road": road,
      "imageUrl": imageUrl,
      "refer_code": referCode,
      "refer_balance": referBalance,
      "location_lat": lat,
      "location_lng": lng,
      "created_at": createdAt?.toIso8601String(),
      "status": status,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      password: json["password"] ?? "",
      division: json["division"] ?? "",
      district: json["district"] ?? "",
      upazila: json["upazila"] ?? "",
      union: json["union"],
      village: json["village"] ?? "",
      ward: json["ward"],
      house: json["house"],
      road: json["road"],
      imageUrl: json["imageUrl"],
      referCode: json["refer_code"],
      referBalance: json["refer_balance"]?.toDouble(),
      lat: (json["location_lat"] as num?)?.toDouble(),
      lng: (json["location_lng"] as num?)?.toDouble(),
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
      status: json["status"],
    );
  }

  factory User.fromSupabase(Map<String, dynamic> data) {
    return User(
      id: data["id"] ?? "",
      name: data["name"] ?? "",
      email: data["email"] ?? "",
      phone: data["phone"] ?? "",
      password: data["password"] ?? "",
      division: data["division"] ?? "",
      district: data["district"] ?? "",
      upazila: data["upazila"] ?? "",
      union: data["union"],
      village: data["village"] ?? "",
      ward: data["ward"],
      house: data["house"],
      road: data["road"],
      imageUrl: data["imageUrl"],
      referCode: data["refer_code"],
      referBalance: data["refer_balance"]?.toDouble(),
      lat: (data["location_lat"] as num?)?.toDouble(),
      lng: (data["location_lng"] as num?)?.toDouble(),
      createdAt: data["created_at"] != null
          ? DateTime.parse(data["created_at"])
          : null,
      status: data["status"],
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "password": password,
      "division": division,
      "district": district,
      "upazila": upazila,
      "union": union,
      "village": village,
      "ward": ward,
      "house": house,
      "road": road,
      "imageUrl": imageUrl,
      "refer_code": referCode,
      "refer_balance": referBalance,
      "location_lat": lat,
      "location_lng": lng,
      "created_at": createdAt?.toIso8601String(),
      "status": status,
    };
  }

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
    String? status,
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
      status: status ?? this.status,
    );
  }
}
