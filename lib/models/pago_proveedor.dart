class PagoProveedor {
  final int id;
  final double monto;
  final DateTime fecha;
  final String notas;

  const PagoProveedor({
    required this.id,
    required this.monto,
    required this.fecha,
    this.notas = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'notas': notas,
      };

  factory PagoProveedor.fromJson(Map<String, dynamic> json) => PagoProveedor(
        id: json['id'] as int,
        monto: (json['monto'] as num?)?.toDouble() ?? 0,
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
        notas: json['notas'] ?? '',
      );
}
