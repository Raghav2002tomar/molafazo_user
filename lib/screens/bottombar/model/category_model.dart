class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final List<SubCategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.subCategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      subCategories: (json['sub_categories'] as List? ?? [])
          .map((e) => SubCategoryModel.fromJson(e))
          .toList(),
    );
  }
}

class SubCategoryModel {
  final int id;
  final String name;
  final String slug;
  final List<ChildCategoryModel> childCategories;

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.childCategories,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      childCategories: (json['child_categories'] as List? ?? [])
          .map((e) => ChildCategoryModel.fromJson(e))
          .toList(),
    );
  }
}

class ChildCategoryModel {
  final int id;
  final String name;
  final String slug;

  ChildCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ChildCategoryModel.fromJson(Map<String, dynamic> json) {
    return ChildCategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}
