class UserModel {
  final String id;
  final String name;
  final String phone;
  final String division;
  final String district;
  final String upazila;
  final String village;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.division,
    required this.district,
    required this.upazila,
    required this.village,
  });

  factory UserModel.fromMap(String id, Map data) {
    return UserModel(
      id: id,
      name: data['name'],
      phone: data['phone'],
      division: data['division'],
      district: data['district'],
      upazila: data['upazila'],
      village: data['village'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'division': division,
        'district': district,
        'upazila': upazila,
        'village': village,
      };
}
