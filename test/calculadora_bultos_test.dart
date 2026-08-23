import 'package:flutter_test/flutter_test.dart';
import 'package:bodegapro/screens/inventario/calculadora_bultos.dart';

void main() {
  group('Calculadora de compra por bultos', () {
    test('el margen es sobre el PVP, no sobre el costo', () {
      // costo unitario 10, 30% deseado → 10 / (1 - 0.30) = 14.2857
      // (si fuera margen sobre costo daría 13.00, que NO es lo que hace el original)
      final r = CalculoBultos.calcular(
        costoBulto: 100,
        unidadesPorBulto: 10,
        cantidadBultos: 1,
        gananciaPct: 30,
        conIva: false,
      )!;
      expect(r.costoUnitario, closeTo(10, 0.0001));
      expect(r.precioFinal, closeTo(14.2857, 0.001));
      expect(r.precioFinal, isNot(closeTo(13.0, 0.01)));
    });

    test('el margen real coincide con el % pedido', () {
      final r = CalculoBultos.calcular(
        costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 1, gananciaPct: 30, conIva: false,
      )!;
      expect(r.margenRealPct, closeTo(30, 0.01));
    });

    test('varios bultos multiplican el total de unidades sin mover el costo unitario', () {
      final r = CalculoBultos.calcular(
        costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 5, gananciaPct: 30, conIva: false,
      )!;
      expect(r.totalUnidades, 50);
      expect(r.costoUnitario, closeTo(10, 0.0001));
      expect(r.gananciaTotal, closeTo(r.gananciaUnitaria * 50, 0.0001));
    });

    test('el IVA 16% se aplica sobre el precio de venta', () {
      final sin = CalculoBultos.calcular(
        costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 1, gananciaPct: 30, conIva: false,
      )!;
      final con = CalculoBultos.calcular(
        costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 1, gananciaPct: 30, conIva: true,
      )!;
      expect(con.precioFinal, closeTo(sin.precioFinal * 1.16, 0.0001));
    });

    test('el reparto 50/30/20 suma la ganancia total', () {
      final r = CalculoBultos.calcular(
        costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 2, gananciaPct: 40, conIva: false,
      )!;
      expect(r.reinversion, closeTo(r.gananciaTotal * 0.5, 0.0001));
      expect(r.gastos, closeTo(r.gananciaTotal * 0.3, 0.0001));
      expect(r.gananciaNeta, closeTo(r.gananciaTotal * 0.2, 0.0001));
      expect(r.reinversion + r.gastos + r.gananciaNeta, closeTo(r.gananciaTotal, 0.0001));
    });

    test('sin ganancia el precio es igual al costo', () {
      final r = CalculoBultos.calcular(
        costoBulto: 50, unidadesPorBulto: 5, cantidadBultos: 1, gananciaPct: 0, conIva: false,
      )!;
      expect(r.precioFinal, closeTo(10, 0.0001));
      expect(r.gananciaUnitaria, closeTo(0, 0.0001));
      expect(r.gananciaTotal, closeTo(0, 0.0001));
    });

    test('rechaza margen de 100% o más y datos incompletos', () {
      expect(CalculoBultos.calcular(costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 1, gananciaPct: 100, conIva: false), isNull);
      expect(CalculoBultos.calcular(costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 1, gananciaPct: 150, conIva: false), isNull);
      expect(CalculoBultos.calcular(costoBulto: 0, unidadesPorBulto: 10, cantidadBultos: 1, gananciaPct: 30, conIva: false), isNull);
      expect(CalculoBultos.calcular(costoBulto: 100, unidadesPorBulto: 0, cantidadBultos: 1, gananciaPct: 30, conIva: false), isNull);
    });

    test('cantidad de bultos vacía o cero se trata como 1', () {
      final r = CalculoBultos.calcular(
        costoBulto: 100, unidadesPorBulto: 10, cantidadBultos: 0, gananciaPct: 30, conIva: false,
      )!;
      expect(r.totalUnidades, 10);
    });
  });
}
