class UserModel {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String? altMobile;
  final String? country;
  final String? city;
  final String? profilePhoto;
  final String? govIdType;
  final String? govIdNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.altMobile,
    this.country,
    this.city,
    this.profilePhoto,
    this.govIdType,
    this.govIdNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      altMobile: json['alt_mobile'],
      country: json['country'],
      city: json['city'],
      profilePhoto: json['profile_photo'],
      govIdType: json['gov_id_type'],
      govIdNumber: json['gov_id_number'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "mobile": mobile,
    "alt_mobile": altMobile,
    "country": country,
    "city": city,
    "profile_photo": profilePhoto,
    "gov_id_type": govIdType,
    "gov_id_number": govIdNumber,
  };
}
