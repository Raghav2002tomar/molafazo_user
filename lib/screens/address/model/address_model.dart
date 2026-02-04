class AddressModel {
  final int id;
  final String name;
  final String fullName;
  final String mobile;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.mobile,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      name: json['name'],
      fullName: json['full_name'],
      mobile: json['mobile'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      isDefault: json['is_default'] == 1,
    );
  }
}
