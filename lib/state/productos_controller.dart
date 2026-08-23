import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/producto.dart';
import '../services/analytics_service.dart';

class ProductosController extends ChangeNotifier {
  final List<Producto> productos = [];

  Future<void> cargar() async {
    await AppDatabase.init();
    final json = AppDatabase.getJson('productos') as List?;
    productos
      ..clear()
      ..addAll((json ?? []).map((p) => Producto.fromJson(p)));
    notifyListeners();
  }

  Future<void> _guardar() async {
    await AppDatabase.setJson('productos', productos.map((p) => p.toJson()).toList());
  }

  List<String> get categorias => productos.map((p) => p.categoria).where((c) => c.isNotEmpty).toSet().toList()..sort();
  List<Producto> get stockBajo => productos.where((p) => p.stockBajo).toList();

  int _siguienteId() => productos.isEmpty ? 1 : (productos.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1);

  Future<Producto> crear(Producto producto) async {
    final conId = Producto(
      id: _siguienteId(),
      nombre: producto.nombre,
      emoji: producto.emoji,
      categoria: producto.categoria,
      precio: producto.precio,
      costo: producto.costo,
      stock: producto.stock,
      stockMin: producto.stockMin,
      unidad: producto.unidad,
      imagen: producto.imagen,
      codigo: producto.codigo,
    );
    productos.add(conId);
    await _guardar();
    notifyListeners();
    AnalyticsService.track('producto_agregado', {'es_primer_producto': productos.length == 1});
    return conId;
  }

  Producto? buscarPorCodigo(String codigo) {
    final c = codigo.trim();
    if (c.isEmpty) return null;
    for (final p in productos) {
      if (p.codigo == c) return p;
    }
    return null;
  }

  Future<void> guardar(Producto producto) async {
    final i = productos.indexWhere((p) => p.id == producto.id);
    if (i >= 0) {
      productos[i] = producto;
    } else {
      productos.add(producto);
    }
    await _guardar();
    notifyListeners();
  }

  Future<void> eliminar(int id) async {
    productos.removeWhere((p) => p.id == id);
    await _guardar();
    notifyListeners();
  }

  Future<void> ajustarStock(int id, double delta) async {
    final i = productos.indexWhere((p) => p.id == id);
    if (i < 0) return;
    productos[i] = productos[i].copyWith(stock: (productos[i].stock + delta).clamp(0, double.infinity));
    await _guardar();
    notifyListeners();
  }
}
