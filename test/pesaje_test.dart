import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodegapro/data/app_database.dart';
import 'package:bodegapro/models/producto.dart';
import 'package:bodegapro/state/cart_controller.dart';

void main() {
  setUp(() {
    AppDatabase.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  const arroz = Producto(id: 1, nombre: 'Arroz', precio: 1.20, stock: 10, unidad: 'kg');
  const jabon = Producto(id: 2, nombre: 'Jabón', precio: 2.50, stock: 10, unidad: 'und');

  test('las unidades kg/g/lt/ml se venden por peso, und no', () {
    expect(arroz.esPorPeso, isTrue);
    expect(jabon.esPorPeso, isFalse);
    for (final u in ['kg', 'g', 'lt', 'ml']) {
      expect(Producto(id: 9, nombre: 'x', precio: 1, unidad: u).esPorPeso, isTrue, reason: u);
    }
  });

  test('peso por precio da el subtotal correcto y suma al total del carrito', () async {
    final cart = CartController();
    await cart.cargar();

    cart.agregarPorPeso(arroz, 2.5);

    expect(cart.items.single.qty, 2.5);
    expect(cart.items.single.total, closeTo(3.00, 0.0001)); // 2.5 kg * 1.20
    expect(cart.subtotal, closeTo(3.00, 0.0001));
    expect(cart.total, closeTo(3.00, 0.0001));
  });

  test('pesar el mismo producto reemplaza la línea en vez de sumarla', () async {
    final cart = CartController();
    await cart.cargar();

    cart.agregarPorPeso(arroz, 2.5);
    cart.agregarPorPeso(arroz, 4.0);

    expect(cart.items.length, 1);
    expect(cart.items.single.qty, 4.0);
    expect(cart.total, closeTo(4.8, 0.0001)); // 4 kg * 1.20
  });

  test('un producto por peso y uno por unidad conviven en el mismo total', () async {
    final cart = CartController();
    await cart.cargar();

    cart.agregarPorPeso(arroz, 2.0); // 2.40
    cart.agregarProducto(jabon); //    2.50

    expect(cart.items.length, 2);
    expect(cart.total, closeTo(4.90, 0.0001));
  });

  test('la etiqueta del carrito muestra la cantidad pesada y sigue el cambio de cantidad', () async {
    final cart = CartController();
    await cart.cargar();

    cart.agregarPorPeso(arroz, 2.5);
    expect(cart.items.single.etiqueta, 'Arroz (2.500 kg)');

    // Los pesos enteros se muestran sin decimales ("3 kg", no "3.000 kg").
    cart.cambiarCantidad(0, 0.5);
    expect(cart.items.single.etiqueta, 'Arroz (3 kg)');

    cart.agregarProducto(jabon);
    expect(cart.items.last.etiqueta, 'Jabón');
  });

  test('la venta confirmada conserva el peso y el total', () async {
    final cart = CartController();
    await cart.cargar();

    cart.agregarPorPeso(arroz, 2.5);
    final venta = await cart.confirmarVenta(metodo: 'Efectivo \$', recibidoUsd: 5);

    expect(venta.totalUsd, closeTo(3.00, 0.0001));
    expect(venta.items.single.qty, 2.5);
    expect(venta.items.single.esPorPeso, isTrue);
    expect(venta.vueltoUsd, closeTo(2.00, 0.0001));
  });

  test('el peso sobrevive a guardar y releer la venta en JSON', () {
    final original = const Producto(id: 1, nombre: 'Arroz', precio: 1.20, stock: 10, unidad: 'kg');
    final copia = Producto.fromJson(original.toJson());
    expect(copia.unidad, 'kg');
    expect(copia.esPorPeso, isTrue);
  });
}
