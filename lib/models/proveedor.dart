import 'pago_proveedor.dart';

class Proveedor {
  final int id;
  final String nombre;
  final String telefono;
  final String producto;
  final double deudaPendiente;
  final DateTime? ultimoPago;
  final List<PagoProveedor> historial;

  const Proveedor({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.producto = '',
    this.deudaPendiente = 0,
    this.ultimoPago,
    this.historial = const [],
  });

  Proveedor copyWith({
    String? nombre,
    String? telefono,
    String? producto,
    double? deudaPendiente,
    DateTime? ultimoPago,
    List<PagoProveedor>? historial,
  }) {
    return Proveedor(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      producto: producto ?? this.producto,
      deudaPendiente: deudaPendiente ?? this.deudaPendiente,
      ultimoPago: ultimoPago ?? this.ultimoPago,
      historial: historial ?? this.historial,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'producto': producto,
        'deudaPendiente': deudaPendiente,
        'ultimoPago': ultimoPago?.toIso8601String(),
        'historial': historial.map((h) => h.toJson()).toList(),
      };

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
        id: json['id'] as int,
        nombre: json['nombre'] ?? '',
        telefono: json['telefono'] ?? '',
        producto: json['producto'] ?? '',
        deudaPendiente: (json['deudaPendiente'] as num?)?.toDouble() ?? 0,
        ultimoPago: json['ultimoPago'] != null ? DateTime.tryParse(json['ultimoPago']) : null,
        historial: ((json['historial'] as List?) ?? []).map((h) => PagoProveedor.fromJson(h as Map<String, dynamic>)).toList(),
      );
}
