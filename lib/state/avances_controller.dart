import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/avance.dart';

class AvancesController extends ChangeNotifier {
  final List<Avance> avances = [];
  final Map<String, double> comisiones = {...Avance.comisionesPorDefecto};

  Future<void> cargar() async {
    await AppDatabase.init();
    final json = AppDatabase.getJson('avances') as List?;
    avances
      ..clear()
      ..addAll((json ?? []).map((a) => Avance.fromJson(a)));

    final com = AppDatabase.getJson('avanceComisiones') as Map<String, dynamic>?;
    if (com != null) {
      for (final entry in com.entries) {
        final valor = (entry.value as num?)?.toDouble();
        if (valor != null) comisiones[entry.key] = valor;
      }
    }
    notifyListeners();
  }

  double comisionDe(String modalidad) => comisiones[modalidad] ?? 0;

  Future<void> guardarComisiones(Map<String, double> nuevas) async {
    comisiones.addAll(nuevas);
    await AppDatabase.setJson('avanceComisiones', comisiones);
    notifyListeners();
  }

  Future<Avance> registrar({
    required double monto,
    required double comisionPct,
    required String modalidad,
    required TipoEfectivo tipo,
    String cliente = '',
    String referencia = '',
  }) async {
    final avance = Avance(
      id: 'av${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      cliente: cliente,
      monto: monto,
      tipoEfectivo: tipo,
      comisionPct: comisionPct,
      modalidad: modalidad,
      referencia: referencia,
    );
    avances.insert(0, avance);
    await _guardar();
    notifyListeners();
    return avance;
  }

  Future<void> eliminar(String id) async {
    avances.removeWhere((a) => a.id == id);
    await _guardar();
    notifyListeners();
  }

  Future<void> _guardar() async {
    await AppDatabase.setJson('avances', avances.map((a) => a.toJson()).toList());
  }

  bool _esHoy(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  List<Avance> get avancesHoy => avances.where((a) => _esHoy(a.fecha)).toList();
  int get operacionesHoy => avancesHoy.length;
  double get efectivoEntregadoHoy => avancesHoy.fold(0, (s, a) => s + a.monto);
  double get cobradoHoy => avancesHoy.fold(0, (s, a) => s + a.totalCobrado);
  double get gananciaTotal => avances.fold(0, (s, a) => s + a.ganancia);
  double get gananciaHoy => avancesHoy.fold(0, (s, a) => s + a.ganancia);
}
