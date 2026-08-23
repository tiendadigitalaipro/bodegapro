enum TipoMovimiento { entrada, salida }

class CajaMovimiento {
  final String id;
  final DateTime openAt;
  final TipoMovimiento type;
  final double amount;
  final String reason;
  final DateTime at;
  final String responsable;

  const CajaMovimiento({
    required this.id,
    required this.openAt,
    required this.type,
    required this.amount,
    required this.reason,
    required this.at,
    required this.responsable,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'openAt': openAt.toIso8601String(),
        'type': type.name,
        'amount': amount,
        'reason': reason,
        'at': at.toIso8601String(),
        'responsable': responsable,
      };

  factory CajaMovimiento.fromJson(Map<String, dynamic> json) => CajaMovimiento(
        id: json['id'].toString(),
        openAt: DateTime.tryParse(json['openAt'] ?? '') ?? DateTime.now(),
        type: json['type'] == 'entrada' ? TipoMovimiento.entrada : TipoMovimiento.salida,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] ?? '',
        at: DateTime.tryParse(json['at'] ?? '') ?? DateTime.now(),
        responsable: json['responsable'] ?? '',
      );
}
