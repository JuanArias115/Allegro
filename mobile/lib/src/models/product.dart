import 'enums.dart';

class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final double currentPrice;
  final bool isActive;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.currentPrice,
    required this.isActive,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: ProductCategory.fromWire(json['category'] as String),
        currentPrice: (json['currentPrice'] as num).toDouble(),
        isActive: json['isActive'] as bool,
        imageUrl: json['imageUrl'] as String?,
      );

  static Map<String, dynamic> toUpsertJson({
    required String name,
    required ProductCategory category,
    required double currentPrice,
    required bool isActive,
    String? imageUrl,
  }) =>
      {
        'name': name,
        'category': category.wire,
        'currentPrice': currentPrice,
        'isActive': isActive,
        'imageUrl': imageUrl,
      };
}
