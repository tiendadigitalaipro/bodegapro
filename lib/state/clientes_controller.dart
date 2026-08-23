import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/cliente.dart';

class ClientesController extends ChangeNotifier {
  final List<Cliente> clientes = [];

  Future<void> cargar() async {
    await AppDatabase.init();
    final json = AppDatabase.getJson('clientes') as List?;
    clientes
      ..clear()
      ..addAll((json ?? []).map((c) => Cliente.fromJson(c)));
    notifyListeners();
  }

  Future<void> _guardar() async {
    await AppDatabase.setJson('clientes', clientes.map((c) => c.toJson()).toList());
  }

  int _siguienteId() => clientes.isEmpty ? 1 : (clientes.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1);

  Future<void> guardar(Cliente cliente) async {
    final i = clientes.indexWhere((c) => c.id == cliente.id);
    if (i >= 0) {
      clientes[i] = cliente;
    } else {
      clientes.add(Cliente(
        id: _siguienteId(),
        nombre: cliente.nombre,
        telefono: cliente.telefono,
        cedula: cliente.cedula,
        limite: cliente.limite,
        notas: cliente.notas,
      ));
    }
    await _guardar();
    notifyListeners();
  }

  Future<void> eliminar(int id) async {
    clientes.removeWhere((c) => c.id == id);
    await _guardar();
    notifyListeners();
  }

  Future<void> registrarFiado(int clienteId, double monto) async {
    final i = clientes.indexWhere((c) => c.id == clienteId);
    if (i < 0) return;
    clientes[i] = clientes[i].copyWith(deuda: clientes[i].deuda + monto, ultimaCompra: DateTime.now());
    await _guardar();
    notifyListeners();
  }

  Future<void> registrarAbono(int clienteId, double monto) async {
    final i = clientes.indexWhere((c) => c.id == clienteId);
    if (i < 0) return;
    final nuevaDeuda = (clientes[i].deuda - monto).clamp(0.0, double.infinity);
    clientes[i] = clientes[i].copyWith(deuda: nuevaDeuda);
    await _guardar();
    notifyListeners();
  }
}
