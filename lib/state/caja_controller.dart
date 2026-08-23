import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/caja_movimiento.dart';
import '../models/caja_turno.dart';

/// Estado de apertura/cierre de turno de caja — equivalente a cajaAbrir(),
/// cajaMovimiento(), cajaCerrar() de zync-electronics-app/index.html.
/// El resumen de ventas por turno lo arma CajaScreen combinando esto con
/// CartController.historialVentas, igual que en BarberFlow.
class CajaController extends ChangeNotifier {
  CajaTurnoActivo? turnoActivo;
  final List<CajaMovimiento> movimientos = [];
  final List<CajaTurnoCerrado> historialTurnos = [];

  Future<void> cargar() async {
    await AppDatabase.init();
    final turnoJson = AppDatabase.getJson('cajaTurnoActivo') as Map<String, dynamic>?;
    turnoActivo = turnoJson != null ? CajaTurnoActivo.fromJson(turnoJson) : null;

    final movJson = AppDatabase.getJson('cajaMovimientos') as List?;
    movimientos
      ..clear()
      ..addAll((movJson ?? []).map((m) => CajaMovimiento.fromJson(m)));

    final turnosJson = AppDatabase.getJson('cajaTurnos') as List?;
    historialTurnos
      ..clear()
      ..addAll((turnosJson ?? []).map((t) => CajaTurnoCerrado.fromJson(t)));

    notifyListeners();
  }

  /// Movimientos del turno actualmente abierto.
  List<CajaMovimiento> get movimientosDelTurno {
    if (turnoActivo == null) return [];
    return movimientos.where((m) => m.openAt == turnoActivo!.openAt).toList();
  }

  Future<void> abrir({required double montoInicial, required String responsable}) async {
    turnoActivo = CajaTurnoActivo(
      inicial: montoInicial,
      responsable: responsable.trim().isEmpty ? 'Admin' : responsable.trim(),
      openAt: DateTime.now(),
    );
    await AppDatabase.setJson('cajaTurnoActivo', turnoActivo!.toJson());
    notifyListeners();
  }

  Future<void> registrarMovimiento({
    required TipoMovimiento tipo,
    required double monto,
    required String motivo,
  }) async {
    if (turnoActivo == null) return;
    final mov = CajaMovimiento(
      id: 'cashmov${DateTime.now().millisecondsSinceEpoch}',
      openAt: turnoActivo!.openAt,
      type: tipo,
      amount: monto,
      reason: motivo,
      at: DateTime.now(),
      responsable: turnoActivo!.responsable,
    );
    movimientos.insert(0, mov);
    await AppDatabase.setJson('cajaMovimientos', movimientos.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  Future<void> cerrar({
    required double ventasTotal,
    required double efectivo,
    required double digital,
    required double credito,
    required double montoContado,
  }) async {
    final turno = turnoActivo;
    if (turno == null) return;

    final entradas = movimientosDelTurno.where((m) => m.type == TipoMovimiento.entrada).fold(0.0, (s, m) => s + m.amount);
    final salidas = movimientosDelTurno.where((m) => m.type == TipoMovimiento.salida).fold(0.0, (s, m) => s + m.amount);
    final esperado = turno.inicial + efectivo + entradas - salidas;

    final cerrado = CajaTurnoCerrado(
      id: 'turno${DateTime.now().millisecondsSinceEpoch}',
      responsable: turno.responsable,
      openAt: turno.openAt,
      closeAt: DateTime.now(),
      inicial: turno.inicial,
      ventas: ventasTotal,
      efectivo: efectivo,
      digital: digital,
      credito: credito,
      entradas: entradas,
      salidas: salidas,
      esperado: esperado,
      contado: montoContado,
      diff: montoContado - esperado,
    );
    historialTurnos.insert(0, cerrado);
    await AppDatabase.setJson('cajaTurnos', historialTurnos.map((t) => t.toJson()).toList());

    turnoActivo = null;
    await AppDatabase.remove('cajaTurnoActivo');
    notifyListeners();
  }
}
