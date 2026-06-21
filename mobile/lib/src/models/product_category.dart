class ProductCategory {
  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isActive,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
}
