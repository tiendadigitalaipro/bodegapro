/// Formato dual USD/Bs — Mercado Logic Pro muestra siempre el monto en
/// dólares y su equivalente en bolívares según la tasa de cambio configurada,
/// a diferencia de BarberFlow/ZYNC que solo manejan una moneda.
String formatMoney(double n) {
  final fixed = n.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '\$ $intPart.${parts[1]}';
}

String formatBs(double n, double tasaCambio) => formatMoney(n * tasaCambio).replaceFirst('\$', 'Bs.');
