import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/cart_item.dart';
import '../models/pago_parcial.dart';
import '../models/producto.dart';
import '../models/venta.dart';

/// Estado del carrito y checkout — equivalente a STATE.cart + procesarVenta()
/// de bodega-pro-v9.html.
class CartController extends ChangeNotifier {
  final List<CartItem> items = [];
  double descuentoUsd = 0;
  double tasaCambio = 40;
  final List<Venta> historialVentas = [];

  Future<void> cargar() async {
    await AppDatabase.init();
    tasaCambio = AppDatabase.getDouble('tasa') ?? 40;
    final ventasJson = AppDatabase.getJson('ventas') as List?;
    historialVentas
      ..clear()
      ..addAll((ventasJson ?? []).map((v) => Venta.fromJson(v)));
    notifyListeners();
  }

  Future<void> actualizarTasa(double nuevaTasa) async {
    tasaCambio = nuevaTasa;
    await AppDatabase.setDouble('tasa', tasaCambio);
    notifyListeners();
  }

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get total => (subtotal - descuentoUsd).clamp(0, double.infinity);
  double get totalBs => total * tasaCambio;

  void agregarProducto(Producto p) {
    final existente = items.indexWhere((i) => i.productId == p.id);
    if (existente >= 0) {
      items[existente] = items[existente].copyWith(qty: items[existente].qty + 1);
    } else {
      items.add(CartItem(productId: p.id, nombre: p.nombre, emoji: p.emoji, precio: p.precio));
    }
    notifyListeners();
  }

  /// Productos por peso/volumen: la cantidad pesada reemplaza la línea
  /// existente en vez de sumarse, igual que _confirmarPesaje() del original.
  void agregarPorPeso(Producto p, double peso) {
    items.removeWhere((i) => i.productId == p.id);
    items.add(CartItem(
      productId: p.id,
      nombre: p.nombre,
      emoji: p.emoji,
      precio: p.precio,
      qty: peso,
      esPorPeso: true,
      unidad: p.unidad,
    ));
    notifyListeners();
  }

  void cambiarCantidad(int index, double delta) {
    final nuevaQty = items[index].qty + delta;
    if (nuevaQty <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(qty: nuevaQty);
    }
    notifyListeners();
  }

  void quitar(int index) {
    items.removeAt(index);
    notifyListeners();
  }

  void setDescuento(double valor) {
    descuentoUsd = valor;
    notifyListeners();
  }

  void vaciar() {
    items.clear();
    descuentoUsd = 0;
    notifyListeners();
  }

  Future<Venta> confirmarVenta({
    required String metodo,
    required double recibidoUsd,
    String notas = '',
    List<PagoParcial> pagosMixtos = const [],
  }) async {
    final venta = Venta(
      id: DateTime.now().millisecondsSinceEpoch,
      fecha: DateTime.now(),
      items: List.of(items),
      subtotalUsd: subtotal,
      descuentoUsd: descuentoUsd,
      totalUsd: total,
      metodo: metodo,
      recibidoUsd: recibidoUsd,
      vueltoUsd: (recibidoUsd - total).clamp(0, double.infinity),
      tasa: tasaCambio,
      notas: notas,
      pagosMixtos: pagosMixtos,
    );

    historialVentas.insert(0, venta);
    await AppDatabase.setJson('ventas', historialVentas.map((v) => v.toJson()).toList());

    vaciar();
    notifyListeners();
    return venta;
  }

  Future<void> registrarDevolucion(int ventaId, {required bool total, double montoParcial = 0, required String motivo}) async {
    final i = historialVentas.indexWhere((v) => v.id == ventaId);
    if (i < 0) return;
    final venta = historialVentas[i];
    historialVentas[i] = venta.copyWith(
      estadoDevolucion: total ? EstadoDevolucion.total : EstadoDevolucion.parcial,
      montoDevuelto: total ? venta.totalUsd : montoParcial,
      motivoDevolucion: motivo,
    );
    await AppDatabase.setJson('ventas', historialVentas.map((v) => v.toJson()).toList());
    notifyListeners();
  }
}
