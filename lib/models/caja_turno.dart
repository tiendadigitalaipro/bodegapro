class CajaTurnoActivo {
  final double inicial;
  final String responsable;
  final DateTime openAt;

  const CajaTurnoActivo({required this.inicial, required this.responsable, required this.openAt});

  Map<String, dynamic> toJson() => {
        'inicial': inicial,
        'responsable': responsable,
        'openAt': openAt.toIso8601String(),
      };

  factory CajaTurnoActivo.fromJson(Map<String, dynamic> json) => CajaTurnoActivo(
        inicial: (json['inicial'] as num?)?.toDouble() ?? 0,
        responsable: json['responsable'] ?? 'Admin',
        openAt: DateTime.tryParse(json['openAt'] ?? '') ?? DateTime.now(),
      );
}

/// Turno ya cerrado — queda en el historial.
class CajaTurnoCerrado {
  final String id;
  final String responsable;
  final DateTime openAt;
  final DateTime closeAt;
  final double inicial;
  final double ventas;
  final double efectivo;
  final double digital;
  final double credito;
  final double entradas;
  final double salidas;
  final double esperado;
  final double contado;
  final double diff;

  const CajaTurnoCerrado({
    required this.id,
    required this.responsable,
    required this.openAt,
    required this.closeAt,
    required this.inicial,
    required this.ventas,
    required this.efectivo,
    required this.digital,
    required this.credito,
    required this.entradas,
    required this.salidas,
    required this.esperado,
    required this.contado,
    required this.diff,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'responsable': responsable,
        'openAt': openAt.toIso8601String(),
        'closeAt': closeAt.toIso8601String(),
        'inicial': inicial,
        'ventas': ventas,
        'efectivo': efectivo,
        'digital': digital,
        'credito': credito,
        'entradas': entradas,
        'salidas': salidas,
        'esperado': esperado,
        'contado': contado,
        'diff': diff,
      };

  factory CajaTurnoCerrado.fromJson(Map<String, dynamic> json) => CajaTurnoCerrado(
        id: json['id'].toString(),
        responsable: json['responsable'] ?? '',
        openAt: DateTime.tryParse(json['openAt'] ?? '') ?? DateTime.now(),
        closeAt: DateTime.tryParse(json['closeAt'] ?? '') ?? DateTime.now(),
        inicial: (json['inicial'] as num?)?.toDouble() ?? 0,
        ventas: (json['ventas'] as num?)?.toDouble() ?? 0,
        efectivo: (json['efectivo'] as num?)?.toDouble() ?? 0,
        digital: (json['digital'] as num?)?.toDouble() ?? 0,
        credito: (json['credito'] as num?)?.toDouble() ?? 0,
        entradas: (json['entradas'] as num?)?.toDouble() ?? 0,
        salidas: (json['salidas'] as num?)?.toDouble() ?? 0,
        esperado: (json['esperado'] as num?)?.toDouble() ?? 0,
        contado: (json['contado'] as num?)?.toDouble() ?? 0,
        diff: (json['diff'] as num?)?.toDouble() ?? 0,
      );
}
