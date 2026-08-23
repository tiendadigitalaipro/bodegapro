import '../models/metodo_pago.dart';
import '../models/venta.dart';

typedef ResumenCaja = ({double total, double efectivo, double otros, Map<String, double> porMetodo});

/// Explota cada venta en sus métodos reales: una venta normal cuenta entera
/// en `venta.metodo`; una venta en Pago Mixto se reparte según
/// `pagosMixtos` para que cada parte se sume al método correcto en caja.
Map<String, double> desglosePorMetodo(List<Venta> ventas) {
  final mapa = <String, double>{};
  for (final v in ventas) {
    if (v.metodo == 'Pago Mixto' && v.pagosMixtos.isNotEmpty) {
      for (final p in v.pagosMixtos) {
        mapa[p.metodo] = (mapa[p.metodo] ?? 0) + p.montoUsd;
      }
    } else {
      mapa[v.metodo] = (mapa[v.metodo] ?? 0) + v.totalUsd;
    }
  }
  return mapa;
}

ResumenCaja resumenCaja(List<Venta> ventas, DateTime openAt) {
  final delTurno = ventas.where((v) => !v.fecha.isBefore(openAt)).toList();
  final porMetodo = desglosePorMetodo(delTurno);
  final nombresEfectivo = metodosPago.where((m) => m.esEfectivo).map((m) => m.nombre).toSet();
  return (
    total: delTurno.fold(0.0, (s, v) => s + v.totalUsd),
    efectivo: porMetodo.entries.where((e) => nombresEfectivo.contains(e.key)).fold(0.0, (s, e) => s + e.value),
    otros: porMetodo.entries.where((e) => !nombresEfectivo.contains(e.key)).fold(0.0, (s, e) => s + e.value),
    porMetodo: porMetodo,
  );
}
