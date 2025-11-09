class User {
  final String uid;
  final String name;
  final String phone;
  final String password;
  final String division;
  final String district;
  final String upazila;
  final String village;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;

  User({
    required this.uid,
    required this.name,
    required this.phone,
    required this.password,
    required this.division,
    required this.district,
    required this.upazila,
    required this.village,
    this.imageUrl,
    this.lat,
    this.lng,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name": name,
      "phone": phone,
      "password": password,
      "division": division,
      "district": district,
      "upazila": upazila,
      "village": village,
      "imageUrl": imageUrl,
      "location_lat": lat,
      "location_lng": lng,
      "created_at": createdAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json["uid"],
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
      password: json["password"] ?? "",
      division: json["division"] ?? "",
      district: json["district"] ?? "",
      upazila: json["upazila"] ?? "",
      village: json["village"] ?? "",
      imageUrl: json["imageUrl"],
      lat: (json["location_lat"] as num?)?.toDouble(),
      lng: (json["location_lng"] as num?)?.toDouble(),
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
    );
  }
}
