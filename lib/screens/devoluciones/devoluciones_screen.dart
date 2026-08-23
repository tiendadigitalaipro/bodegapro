import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../state/cart_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class DevolucionesScreen extends StatelessWidget {
  const DevolucionesScreen({super.key});

  bool _esHoy(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<CartController>().historialVentas;
    final devueltas = ventas.where((v) => v.estadoDevolucion != EstadoDevolucion.ninguna).toList();
    final hoy = devueltas.where((v) => _esHoy(v.fecha)).length;
    final montoTotal = devueltas.fold<double>(0, (s, v) => s + v.montoDevuelto);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _StatBox('Total devoluciones', '${devueltas.length}')),
            const SizedBox(width: 10),
            Expanded(child: _StatBox('Hoy', '$hoy')),
            const SizedBox(width: 10),
            Expanded(child: _StatBox('Monto', formatMoney(montoTotal))),
          ]),
          const SizedBox(height: 16),
          if (devueltas.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Sin devoluciones registradas', style: TextStyle(color: Colors.white.withValues(alpha: 0.4)))))
          else
            ...devueltas.reversed.map((v) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.undo, color: Colors.redAccent),
                    title: Text('${formatMoney(v.montoDevuelto)} · ${v.estadoDevolucion == EstadoDevolucion.total ? 'Total' : 'Parcial'}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(v.motivoDevolucion, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                )),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(value, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
