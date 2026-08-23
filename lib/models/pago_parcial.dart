/// Una parte de un pago mixto: cuánto se pagó con un método específico.
/// El monto siempre está en USD (igual que Venta.totalUsd) para que el
/// desglose de caja sume sin depender de la tasa vigente al momento de leer.
class PagoParcial {
  final String metodo;
  final double montoUsd;

  const PagoParcial({required this.metodo, required this.montoUsd});

  Map<String, dynamic> toJson() => {'metodo': metodo, 'montoUsd': montoUsd};

  factory PagoParcial.fromJson(Map<String, dynamic> json) => PagoParcial(
        metodo: json['metodo'] ?? '',
        montoUsd: (json['montoUsd'] as num?)?.toDouble() ?? 0,
      );
}
