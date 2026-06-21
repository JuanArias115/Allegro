import 'package:allegro/src/features/products/product_grouping.dart';
import 'package:allegro/src/models/product.dart';
import 'package:allegro/src/models/product_category.dart';
import 'package:flutter_test/flutter_test.dart';

ProductCategory _cat(String id, String name, int order, {bool active = true}) =>
    ProductCategory.fromJson({
      'id': id,
      'name': name,
      'displayOrder': order,
      'isActive': active,
    });

Product _prod(String id, String name, String catId, String catName) =>
    Product.fromJson({
      'id': id,
      'name': name,
      'categoryId': catId,
      'categoryName': catName,
      'currentPrice': 1000,
      'isActive': true,
      'imageUrl': null,
    });

void main() {
  group('ProductCategory', () {
    test('parsea desde JSON del backend', () {
      final c = _cat('c1', 'Bebidas', 1);
      expect(c.id, 'c1');
      expect(c.name, 'Bebidas');
      expect(c.displayOrder, 1);
      expect(c.isActive, true);
    });
  });

  group('Product', () {
    test('parsea categoryId y categoryName', () {
      final p = _prod('p1', 'Café', 'c1', 'Bebidas');
      expect(p.categoryId, 'c1');
      expect(p.categoryName, 'Bebidas');
    });
  });

  group('Agrupación dinámica de productos', () {
    test(
      'ordena por DisplayOrder, productos por nombre y oculta categorías vacías',
      () {
        final categories = [
          _cat('snacks', 'Snacks', 3),
          _cat('bebidas', 'Bebidas', 1),
          _cat('menu', 'Menú', 2),
          _cat('vacia', 'Servicios', 4), // sin productos -> no debe aparecer
        ];
        final products = [
          _prod('1', 'Pizza', 'menu', 'Menú'),
          _prod('2', 'Agua', 'bebidas', 'Bebidas'),
          _prod('3', 'Cerveza', 'bebidas', 'Bebidas'),
          _prod('4', 'Galletas', 'snacks', 'Snacks'),
        ];

        final groups = groupProductsByCategory(products, categories);

        // Orden por DisplayOrder: Bebidas(1), Menú(2), Snacks(3). "Servicios" se oculta.
        expect(groups.map((g) => g.categoryName), [
          'Bebidas',
          'Menú',
          'Snacks',
        ]);
        // Productos por nombre dentro de Bebidas: Agua, Cerveza.
        expect(groups.first.products.map((p) => p.name), ['Agua', 'Cerveza']);
      },
    );

    test('no pierde productos cuya categoría no está en la lista', () {
      final categories = [_cat('bebidas', 'Bebidas', 1)];
      final products = [
        _prod('1', 'Agua', 'bebidas', 'Bebidas'),
        _prod('2', 'Item viejo', 'huerfana', 'Descontinuada'),
      ];

      final groups = groupProductsByCategory(products, categories);

      expect(groups.length, 2);
      final total = groups.fold<int>(0, (a, g) => a + g.products.length);
      expect(total, 2); // ningún producto se pierde
      // La categoría conocida va primero (DisplayOrder 1); la huérfana al final.
      expect(groups.first.categoryName, 'Bebidas');
      expect(groups.last.categoryName, 'Descontinuada');
    });
  });
}
