import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../state/cart_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  bool _esHoy(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _estaEnSemana(DateTime d) {
    final n = DateTime.now();
    final inicio = DateTime(n.year, n.month, n.day).subtract(Duration(days: n.weekday - 1));
    return !d.isBefore(inicio);
  }

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<CartController>().historialVentas;
    final ventasHoy = ventas.where((v) => _esHoy(v.fecha)).toList();
    final ventasSemana = ventas.where((v) => _estaEnSemana(v.fecha)).toList();
    final totalHoy = ventasHoy.fold<double>(0, (s, v) => s + v.totalUsd);
    final totalSemana = ventasSemana.fold<double>(0, (s, v) => s + v.totalUsd);
    final promedio = ventasHoy.isEmpty ? 0.0 : totalHoy / ventasHoy.length;

    final porMetodo = <String, double>{};
    for (final v in ventasHoy) {
      porMetodo[v.metodo] = (porMetodo[v.metodo] ?? 0) + v.totalUsd;
    }

    if (ventas.isEmpty) {
      return Center(child: Text('Todavía no hay ventas registradas.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard('Ventas hoy', formatMoney(totalHoy), Icons.today),
              _StatCard('Ventas semana', formatMoney(totalSemana), Icons.date_range),
              _StatCard('Tickets hoy', '${ventasHoy.length}', Icons.receipt_long),
              _StatCard('Ticket promedio', formatMoney(promedio), Icons.trending_up),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Ventas de hoy por método', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (porMetodo.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Sin ventas todavía hoy.', style: TextStyle(color: Colors.white38)))
          else
            ...porMetodo.entries.map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined, color: AppColors.indigo),
                    title: Text(e.key, style: const TextStyle(color: Colors.white)),
                    trailing: Text(formatMoney(e.value), style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold)),
                  ),
                )),
          const SizedBox(height: 20),
          const Text('Últimas ventas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...ventas.take(15).map((v) => _VentaTile(v)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: AppColors.indigo),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ]),
      ),
    );
  }
}

class _VentaTile extends StatelessWidget {
  final Venta venta;
  const _VentaTile(this.venta);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${formatMoney(venta.totalUsd)} · ${venta.metodo}', style: const TextStyle(color: Colors.white)),
        subtitle: Text('${venta.fecha.day}/${venta.fecha.month} ${venta.fecha.hour.toString().padLeft(2, '0')}:${venta.fecha.minute.toString().padLeft(2, '0')} · ${venta.items.length} items', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ),
    );
  }
}
