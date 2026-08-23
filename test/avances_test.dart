import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodegapro/data/app_database.dart';
import 'package:bodegapro/models/avance.dart';
import 'package:bodegapro/state/avances_controller.dart';
import 'package:bodegapro/state/empleados_controller.dart';

void main() {
  setUp(() {
    AppDatabase.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  group('Avances de efectivo', () {
    test('la ganancia es el % de comisión y el total cobrado suma esa comisión', () {
      final a = Avance(
        id: 'a1',
        fecha: DateTime(2026, 8, 14),
        monto: 100,
        comisionPct: 10,
        modalidad: 'Pago Móvil',
      );
      expect(a.ganancia, closeTo(10, 0.0001));
      expect(a.totalCobrado, closeTo(110, 0.0001));
      expect(a.simbolo, '\$');
    });

    test('cada modalidad trae su comisión sugerida del original', () async {
      final c = AvancesController();
      await c.cargar();
      expect(c.comisionDe('Transferencia'), 8);
      expect(c.comisionDe('Pago Móvil'), 10);
      expect(c.comisionDe('BioPago'), 8);
      expect(c.comisionDe('Punto Débito'), 10);
      expect(c.comisionDe('Punto Crédito'), 15);
      expect(c.comisionDe('Zelle'), 5);
      expect(c.comisionDe('Binance'), 3);
    });

    test('registrar acumula ganancia y estadísticas del día', () async {
      final c = AvancesController();
      await c.cargar();

      await c.registrar(monto: 100, comisionPct: 10, modalidad: 'Pago Móvil', tipo: TipoEfectivo.usd);
      await c.registrar(monto: 50, comisionPct: 8, modalidad: 'Transferencia', tipo: TipoEfectivo.usd);

      expect(c.avances.length, 2);
      expect(c.operacionesHoy, 2);
      expect(c.efectivoEntregadoHoy, closeTo(150, 0.0001));
      expect(c.gananciaHoy, closeTo(14, 0.0001)); // 10 + 4
      expect(c.cobradoHoy, closeTo(164, 0.0001)); // 110 + 54
      expect(c.gananciaTotal, closeTo(14, 0.0001));
    });

    test('las comisiones editadas se guardan y se releen', () async {
      final c = AvancesController();
      await c.cargar();
      await c.guardarComisiones({'Zelle': 7});
      expect(c.comisionDe('Zelle'), 7);

      final otra = AvancesController();
      await otra.cargar();
      expect(otra.comisionDe('Zelle'), 7);
      expect(otra.comisionDe('Binance'), 3);
    });

    test('el avance sobrevive el round-trip a JSON', () async {
      final c = AvancesController();
      await c.cargar();
      await c.registrar(monto: 200, comisionPct: 15, modalidad: 'Punto Crédito', tipo: TipoEfectivo.bs, cliente: 'Ana');

      final copia = Avance.fromJson(c.avances.single.toJson());
      expect(copia.monto, 200);
      expect(copia.comisionPct, 15);
      expect(copia.tipoEfectivo, TipoEfectivo.bs);
      expect(copia.cliente, 'Ana');
      expect(copia.ganancia, closeTo(30, 0.0001));
      expect(copia.simbolo, 'Bs');
    });
  });

  group('Empleados', () {
    test('crear asigna ids incrementales y detecta usuario repetido', () async {
      final c = EmpleadosController();
      await c.cargar();

      await c.crear(nombre: 'Luis', usuario: 'luis', password: '1234');
      await c.crear(nombre: 'Ana', usuario: 'ana', password: '5678');

      expect(c.empleados.map((e) => e.id), [1, 2]);
      expect(c.usuarioExiste('LUIS'), isTrue);
      expect(c.usuarioExiste('pedro'), isFalse);
    });

    test('alternar activo y eliminar persisten', () async {
      final c = EmpleadosController();
      await c.cargar();
      await c.crear(nombre: 'Luis', usuario: 'luis', password: '1234');

      await c.alternarActivo(1);
      expect(c.empleados.single.activo, isFalse);

      final otra = EmpleadosController();
      await otra.cargar();
      expect(otra.empleados.single.activo, isFalse);

      await c.eliminar(1);
      expect(c.empleados, isEmpty);
    });
  });
}
