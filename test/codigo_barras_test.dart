import 'package:flutter_test/flutter_test.dart';
import 'package:bodegapro/models/producto.dart';
import 'package:bodegapro/state/productos_controller.dart';

void main() {
  group('Búsqueda de producto por código de barras/QR', () {
    test('encuentra el producto cuyo código coincide exacto', () {
      final controller = ProductosController();
      controller.productos.addAll(const [
        Producto(id: 1, nombre: 'Arroz', precio: 2, codigo: '7501234567890'),
        Producto(id: 2, nombre: 'Harina', precio: 1.5, codigo: '7509876543210'),
      ]);
      final encontrado = controller.buscarPorCodigo('7509876543210');
      expect(encontrado?.nombre, 'Harina');
    });

    test('devuelve null si ningún producto tiene ese código', () {
      final controller = ProductosController();
      controller.productos.add(const Producto(id: 1, nombre: 'Arroz', precio: 2, codigo: '111'));
      expect(controller.buscarPorCodigo('999'), isNull);
    });

    test('un código vacío no devuelve productos sin código asignado', () {
      final controller = ProductosController();
      controller.productos.add(const Producto(id: 1, nombre: 'Sin código', precio: 2));
      expect(controller.buscarPorCodigo(''), isNull);
      expect(controller.buscarPorCodigo('   '), isNull);
    });
  });
}
