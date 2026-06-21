class Product {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double currentPrice;
  final bool isActive;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.currentPrice,
    required this.isActive,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    categoryId: json['categoryId'] as String,
    categoryName: (json['categoryName'] as String?) ?? '',
    currentPrice: (json['currentPrice'] as num).toDouble(),
    isActive: json['isActive'] as bool,
    imageUrl: json['imageUrl'] as String?,
  );

  static Map<String, dynamic> toUpsertJson({
    required String name,
    required String categoryId,
    required double currentPrice,
    required bool isActive,
    String? imageUrl,
  }) => {
    'name': name,
    'categoryId': categoryId,
    'currentPrice': currentPrice,
    'isActive': isActive,
    'imageUrl': imageUrl,
  };
}
