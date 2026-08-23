enum TipoEfectivo { usd, bs }

/// Avance de efectivo: el cliente paga por transferencia/punto/etc. y se
/// lleva efectivo. La bodega cobra una comisión sobre el monto — esa
/// comisión es la ganancia de la operación.
class Avance {
  /// Modalidades de cobro con su comisión sugerida (%), tal como en
  /// getAvanceComisiones() de bodega-pro-v9.html.
  static const comisionesPorDefecto = <String, double>{
    'Transferencia': 8,
    'Pago Móvil': 10,
    'BioPago': 8,
    'Punto Débito': 10,
    'Punto Crédito': 15,
    'Zelle': 5,
    'Binance': 3,
  };

  static List<String> get modalidades => comisionesPorDefecto.keys.toList();

  final String id;
  final DateTime fecha;
  final String cliente;
  final double monto;
  final TipoEfectivo tipoEfectivo;
  final double comisionPct;
  final String modalidad;
  final String referencia;

  const Avance({
    required this.id,
    required this.fecha,
    this.cliente = '',
    required this.monto,
    this.tipoEfectivo = TipoEfectivo.usd,
    required this.comisionPct,
    required this.modalidad,
    this.referencia = '',
  });

  double get ganancia => monto * (comisionPct / 100);
  double get totalCobrado => monto + ganancia;
  String get simbolo => tipoEfectivo == TipoEfectivo.usd ? '\$' : 'Bs';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'cliente': cliente,
        'monto': monto,
        'tipoEfectivo': tipoEfectivo.name,
        'comisionPct': comisionPct,
        'modalidad': modalidad,
        'referencia': referencia,
      };

  factory Avance.fromJson(Map<String, dynamic> json) => Avance(
        id: json['id'] ?? '',
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
        cliente: json['cliente'] ?? '',
        monto: (json['monto'] as num?)?.toDouble() ?? 0,
        tipoEfectivo: TipoEfectivo.values.firstWhere(
          (t) => t.name == json['tipoEfectivo'],
          orElse: () => TipoEfectivo.usd,
        ),
        comisionPct: (json['comisionPct'] as num?)?.toDouble() ?? 0,
        modalidad: json['modalidad'] ?? '',
        referencia: json['referencia'] ?? '',
      );
}
