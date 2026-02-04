class ProductModel {
  final int id;
  final String name;
  final String price;
  final String discountPrice;
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPrice,
    required this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"],
      name: json["name"],
      price: json["price"],
      discountPrice: json["discount_price"],
      image: json["primaryimage"] ?? "",
    );
  }
}
