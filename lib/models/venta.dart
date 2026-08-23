import 'cart_item.dart';
import 'pago_parcial.dart';

enum EstadoDevolucion { ninguna, total, parcial }

class Venta {
  final int id;
  final DateTime fecha;
  final List<CartItem> items;
  final double subtotalUsd;
  final double descuentoUsd;
  final double totalUsd;
  final String metodo;
  final double recibidoUsd;
  final double vueltoUsd;
  final double tasa;
  final String notas;
  final EstadoDevolucion estadoDevolucion;
  final double montoDevuelto;
  final String motivoDevolucion;
  /// Desglose por método cuando `metodo == 'Pago Mixto'`. Vacío en ventas
  /// de un solo método. Cada monto está en USD y deben sumar `totalUsd`.
  final List<PagoParcial> pagosMixtos;

  const Venta({
    required this.id,
    required this.fecha,
    required this.items,
    required this.subtotalUsd,
    this.descuentoUsd = 0,
    required this.totalUsd,
    required this.metodo,
    this.recibidoUsd = 0,
    this.vueltoUsd = 0,
    required this.tasa,
    this.notas = '',
    this.estadoDevolucion = EstadoDevolucion.ninguna,
    this.montoDevuelto = 0,
    this.motivoDevolucion = '',
    this.pagosMixtos = const [],
  });

  double get totalBs => totalUsd * tasa;

  Venta copyWith({EstadoDevolucion? estadoDevolucion, double? montoDevuelto, String? motivoDevolucion}) {
    return Venta(
      id: id,
      fecha: fecha,
      items: items,
      subtotalUsd: subtotalUsd,
      descuentoUsd: descuentoUsd,
      totalUsd: totalUsd,
      metodo: metodo,
      recibidoUsd: recibidoUsd,
      vueltoUsd: vueltoUsd,
      tasa: tasa,
      notas: notas,
      estadoDevolucion: estadoDevolucion ?? this.estadoDevolucion,
      montoDevuelto: montoDevuelto ?? this.montoDevuelto,
      motivoDevolucion: motivoDevolucion ?? this.motivoDevolucion,
      pagosMixtos: pagosMixtos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'subtotalUsd': subtotalUsd,
        'descuentoUsd': descuentoUsd,
        'totalUsd': totalUsd,
        'metodo': metodo,
        'recibidoUsd': recibidoUsd,
        'vueltoUsd': vueltoUsd,
        'tasa': tasa,
        'notas': notas,
        'estadoDevolucion': estadoDevolucion.name,
        'montoDevuelto': montoDevuelto,
        'motivoDevolucion': motivoDevolucion,
        'pagosMixtos': pagosMixtos.map((p) => p.toJson()).toList(),
      };

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: json['id'] as int,
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
        items: ((json['items'] as List?) ?? []).map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList(),
        subtotalUsd: (json['subtotalUsd'] as num?)?.toDouble() ?? 0,
        descuentoUsd: (json['descuentoUsd'] as num?)?.toDouble() ?? 0,
        totalUsd: (json['totalUsd'] as num?)?.toDouble() ?? 0,
        metodo: json['metodo'] ?? '',
        recibidoUsd: (json['recibidoUsd'] as num?)?.toDouble() ?? 0,
        vueltoUsd: (json['vueltoUsd'] as num?)?.toDouble() ?? 0,
        tasa: (json['tasa'] as num?)?.toDouble() ?? 40,
        notas: json['notas'] ?? '',
        estadoDevolucion: EstadoDevolucion.values.firstWhere(
          (e) => e.name == json['estadoDevolucion'],
          orElse: () => EstadoDevolucion.ninguna,
        ),
        montoDevuelto: (json['montoDevuelto'] as num?)?.toDouble() ?? 0,
        motivoDevolucion: json['motivoDevolucion'] ?? '',
        pagosMixtos: ((json['pagosMixtos'] as List?) ?? []).map((p) => PagoParcial.fromJson(p as Map<String, dynamic>)).toList(),
      );
}
