import '../core/api/api_client.dart';
import '../models/enums.dart';
import '../models/product.dart';

class ProductRepository {
  final ApiClient _api;
  ProductRepository(this._api);

  Future<List<Product>> getAll({bool onlyActive = false}) async {
    final data = await _api.get<List<dynamic>>('/api/products', query: {'onlyActive': onlyActive});
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> create({
    required String name,
    required ProductCategory category,
    required double currentPrice,
    required bool isActive,
    String? imageUrl,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/api/products',
        body: Product.toUpsertJson(
            name: name, category: category, currentPrice: currentPrice, isActive: isActive, imageUrl: imageUrl));
    return Product.fromJson(data);
  }

  Future<Product> update(
    String id, {
    required String name,
    required ProductCategory category,
    required double currentPrice,
    required bool isActive,
    String? imageUrl,
  }) async {
    final data = await _api.put<Map<String, dynamic>>('/api/products/$id',
        body: Product.toUpsertJson(
            name: name, category: category, currentPrice: currentPrice, isActive: isActive, imageUrl: imageUrl));
    return Product.fromJson(data);
  }
}
