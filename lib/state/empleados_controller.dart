import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/empleado.dart';

class EmpleadosController extends ChangeNotifier {
  final List<Empleado> empleados = [];

  Future<void> cargar() async {
    await AppDatabase.init();
    final json = AppDatabase.getJson('empleados') as List?;
    empleados
      ..clear()
      ..addAll((json ?? []).map((e) => Empleado.fromJson(e)));
    notifyListeners();
  }

  int _siguienteId() => empleados.isEmpty ? 1 : (empleados.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

  Future<void> crear({required String nombre, required String usuario, required String password}) async {
    empleados.add(Empleado(
      id: _siguienteId(),
      nombre: nombre.trim(),
      usuario: usuario.trim(),
      password: password,
    ));
    await _guardar();
    notifyListeners();
  }

  Future<void> eliminar(int id) async {
    empleados.removeWhere((e) => e.id == id);
    await _guardar();
    notifyListeners();
  }

  Future<void> alternarActivo(int id) async {
    final i = empleados.indexWhere((e) => e.id == id);
    if (i < 0) return;
    empleados[i] = empleados[i].copyWith(activo: !empleados[i].activo);
    await _guardar();
    notifyListeners();
  }

  bool usuarioExiste(String usuario) =>
      empleados.any((e) => e.usuario.toLowerCase() == usuario.trim().toLowerCase());

  Future<void> _guardar() async {
    await AppDatabase.setJson('empleados', empleados.map((e) => e.toJson()).toList());
  }
}
