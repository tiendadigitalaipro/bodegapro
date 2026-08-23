import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/pago_proveedor.dart';
import '../models/proveedor.dart';

class ProveedoresController extends ChangeNotifier {
  final List<Proveedor> proveedores = [];

  Future<void> cargar() async {
    await AppDatabase.init();
    final json = AppDatabase.getJson('proveedores') as List?;
    proveedores
      ..clear()
      ..addAll((json ?? []).map((p) => Proveedor.fromJson(p)));
    notifyListeners();
  }

  Future<void> _guardar() async {
    await AppDatabase.setJson('proveedores', proveedores.map((p) => p.toJson()).toList());
  }

  double get deudaTotal => proveedores.fold(0, (s, p) => s + p.deudaPendiente);

  int _siguienteId() => proveedores.isEmpty ? 1 : (proveedores.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1);

  Future<void> guardar(Proveedor proveedor) async {
    final i = proveedores.indexWhere((p) => p.id == proveedor.id);
    if (i >= 0) {
      proveedores[i] = proveedor;
    } else {
      proveedores.add(Proveedor(
        id: _siguienteId(),
        nombre: proveedor.nombre,
        telefono: proveedor.telefono,
        producto: proveedor.producto,
        deudaPendiente: proveedor.deudaPendiente,
      ));
    }
    await _guardar();
    notifyListeners();
  }

  Future<void> eliminar(int id) async {
    proveedores.removeWhere((p) => p.id == id);
    await _guardar();
    notifyListeners();
  }

  Future<void> registrarPago(int proveedorId, double monto, {String notas = ''}) async {
    final i = proveedores.indexWhere((p) => p.id == proveedorId);
    if (i < 0) return;
    final pago = PagoProveedor(id: DateTime.now().millisecondsSinceEpoch, monto: monto, fecha: DateTime.now(), notas: notas);
    final nuevaDeuda = (proveedores[i].deudaPendiente - monto).clamp(0.0, double.infinity);
    proveedores[i] = proveedores[i].copyWith(
      deudaPendiente: nuevaDeuda,
      ultimoPago: DateTime.now(),
      historial: [...proveedores[i].historial, pago],
    );
    await _guardar();
    notifyListeners();
  }
}
