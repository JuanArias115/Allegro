import '../core/api/api_client.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class ProductRepository {
  final ApiClient _api;
  ProductRepository(this._api);

  Future<List<Product>> getAll({bool onlyActive = false}) async {
    final data = await _api.get<List<dynamic>>(
      '/api/products',
      query: {'onlyActive': onlyActive},
    );
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Categorías activas (GET /api/product-categories), ordenadas por el backend.
  Future<List<ProductCategory>> getCategories() async {
    final data = await _api.get<List<dynamic>>('/api/product-categories');
    return data
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> create({
    required String name,
    required String categoryId,
    required double currentPrice,
    required bool isActive,
    String? imageUrl,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/products',
      body: Product.toUpsertJson(
        name: name,
        categoryId: categoryId,
        currentPrice: currentPrice,
        isActive: isActive,
        imageUrl: imageUrl,
      ),
    );
    return Product.fromJson(data);
  }

  Future<Product> update(
    String id, {
    required String name,
    required String categoryId,
    required double currentPrice,
    required bool isActive,
    String? imageUrl,
  }) async {
    final data = await _api.put<Map<String, dynamic>>(
      '/api/products/$id',
      body: Product.toUpsertJson(
        name: name,
        categoryId: categoryId,
        currentPrice: currentPrice,
        isActive: isActive,
        imageUrl: imageUrl,
      ),
    );
    return Product.fromJson(data);
  }
}
