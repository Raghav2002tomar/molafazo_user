class StoreModel {
  final int id;
  final int userId;

  final String name;
  final String email;
  final String mobile;

  final String country;
  final String city;
  final String address;

  final int type; // 1 = Individual, 2 = Business (example)
  final int deliveryBySeller; // 1 = yes, 0 = no
  final int selfPickup; // 1 = yes, 0 = no

  final String? logo;
  final String? description;
  final String workingHours;

  final int statusId;
  final String? approvedAt;

  final String createdAt;
  final String updatedAt;

  final String? governmentId; // stored as JSON string from backend

  StoreModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    required this.type,
    required this.deliveryBySeller,
    required this.selfPickup,
    required this.logo,
    required this.description,
    required this.workingHours,
    required this.statusId,
    required this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.governmentId,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'],
      userId: json['user_id'],

      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',

      country: json['country'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',

      type: json['type'] ?? 0,
      deliveryBySeller: json['delivery_by_seller'] ?? 0,
      selfPickup: json['self_pickup'] ?? 0,

      logo: json['logo'],
      description: json['description'],
      workingHours: json['working_hours'] ?? '',

      statusId: json['status_id'] ?? 0,
      approvedAt: json['approved_at'],

      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',

      governmentId: json['government_id'],
    );
  }
}
