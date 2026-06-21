import '../../models/product.dart';
import '../../models/product_category.dart';

/// Grupo de productos de una categoría, listo para mostrar.
class ProductGroup {
  final String categoryId;
  final String categoryName;
  final int displayOrder;
  final List<Product> products;

  const ProductGroup({
    required this.categoryId,
    required this.categoryName,
    required this.displayOrder,
    required this.products,
  });
}

/// Agrupa productos por categoría usando las categorías recibidas del backend:
/// ordena los grupos por DisplayOrder (luego nombre), los productos por nombre,
/// y oculta las categorías sin productos. No pierde productos: si la categoría de
/// un producto no está en la lista, se agrupa igual por su nombre al final.
List<ProductGroup> groupProductsByCategory(
  List<Product> products,
  List<ProductCategory> categories,
) {
  final orderById = {for (final c in categories) c.id: c.displayOrder};
  final nameById = {for (final c in categories) c.id: c.name};

  final byCategory = <String, List<Product>>{};
  for (final p in products) {
    byCategory.putIfAbsent(p.categoryId, () => []).add(p);
  }

  final groups = <ProductGroup>[];
  byCategory.forEach((id, list) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    groups.add(
      ProductGroup(
        categoryId: id,
        categoryName:
            nameById[id] ?? (list.isNotEmpty ? list.first.categoryName : ''),
        displayOrder: orderById[id] ?? 1 << 30,
        products: list,
      ),
    );
  });

  groups.sort((a, b) {
    final byOrder = a.displayOrder.compareTo(b.displayOrder);
    return byOrder != 0
        ? byOrder
        : a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
  });
  return groups;
}
