import 'package:flutter_test/flutter_test.dart';
import 'package:bodegapro/models/cart_item.dart';
import 'package:bodegapro/models/pago_parcial.dart';
import 'package:bodegapro/models/venta.dart';
import 'package:bodegapro/utils/resumen_caja.dart';

Venta _venta({required String metodo, required double totalUsd, List<PagoParcial> pagosMixtos = const []}) {
  return Venta(
    id: DateTime.now().microsecondsSinceEpoch,
    fecha: DateTime.now(),
    items: const [CartItem(productId: 1, nombre: 'Arroz', emoji: '🌾', precio: 1, qty: 1)],
    subtotalUsd: totalUsd,
    totalUsd: totalUsd,
    metodo: metodo,
    tasa: 40,
    pagosMixtos: pagosMixtos,
  );
}

void main() {
  group('Desglose de caja por método (Pago Mixto)', () {
    test('una venta normal cuenta entera en su propio método', () {
      final ventas = [_venta(metodo: 'Zelle', totalUsd: 20)];
      final desglose = desglosePorMetodo(ventas);
      expect(desglose, {'Zelle': 20.0});
    });

    test('una venta en Pago Mixto se reparte por cada método real, no queda como un solo bloque', () {
      final ventas = [
        _venta(metodo: 'Pago Mixto', totalUsd: 30, pagosMixtos: const [
          PagoParcial(metodo: 'Efectivo \$', montoUsd: 20),
          PagoParcial(metodo: 'Punto Crédito', montoUsd: 10),
        ]),
      ];
      final desglose = desglosePorMetodo(ventas);
      expect(desglose['Efectivo \$'], 20.0);
      expect(desglose['Punto Crédito'], 10.0);
      expect(desglose.containsKey('Pago Mixto'), isFalse, reason: 'el mixto no debe quedar como bloque, solo sus partes reales');
    });

    test('el efectivo de un pago mixto sí cae en el balde de efectivo del cierre de caja', () {
      final openAt = DateTime(2026, 1, 1);
      final ventas = [
        _venta(metodo: 'Pago Mixto', totalUsd: 30, pagosMixtos: const [
          PagoParcial(metodo: 'Efectivo \$', montoUsd: 20),
          PagoParcial(metodo: 'Punto Crédito', montoUsd: 10),
        ])
      ];
      final r = resumenCaja(ventas, openAt);
      expect(r.total, 30.0);
      expect(r.efectivo, 20.0, reason: 'antes del fix, todo Pago Mixto caía en "otros" aunque parte fuera efectivo');
      expect(r.otros, 10.0);
    });

    test('varios pagos mixtos con métodos repetidos se suman correctamente', () {
      final openAt = DateTime(2026, 1, 1);
      final ventas = [
        _venta(metodo: 'Pago Mixto', totalUsd: 15, pagosMixtos: const [
          PagoParcial(metodo: 'Efectivo \$', montoUsd: 10),
          PagoParcial(metodo: 'Zelle', montoUsd: 5),
        ]),
        _venta(metodo: 'Efectivo \$', totalUsd: 8),
      ];
      final r = resumenCaja(ventas, openAt);
      expect(r.porMetodo['Efectivo \$'], 18.0);
      expect(r.porMetodo['Zelle'], 5.0);
      expect(r.efectivo, 18.0);
      expect(r.otros, 5.0);
    });

    test('ventas fuera del turno actual no se cuentan', () {
      final openAt = DateTime(2026, 6, 1);
      final ventas = [
        Venta(id: 1, fecha: DateTime(2026, 5, 1), items: const [], subtotalUsd: 100, totalUsd: 100, metodo: 'Zelle', tasa: 40),
      ];
      final r = resumenCaja(ventas, openAt);
      expect(r.total, 0.0);
    });
  });
}
