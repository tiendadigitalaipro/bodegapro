import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart_controller.dart';
import '../state/clientes_controller.dart';
import '../state/productos_controller.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  bool _esHoy(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<CartController>().historialVentas;
    final clientes = context.watch<ClientesController>().clientes;
    final stockBajo = context.watch<ProductosController>().stockBajo;
    final ventasHoy = ventas.where((v) => _esHoy(v.fecha)).toList();
    final totalHoy = ventasHoy.fold<double>(0, (s, v) => s + v.totalUsd);
    final deudaClientes = clientes.fold<double>(0, (s, c) => s + c.deuda);

    final porProducto = <String, double>{};
    for (final v in ventas) {
      for (final i in v.items) {
        porProducto[i.nombre] = (porProducto[i.nombre] ?? 0) + i.qty;
      }
    }
    final top5 = porProducto.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatCard('Ventas hoy', formatMoney(totalHoy), Icons.point_of_sale),
              _StatCard('Tickets hoy', '${ventasHoy.length}', Icons.receipt_long),
              _StatCard('Stock bajo', '${stockBajo.length}', Icons.inventory_2),
              _StatCard('Fiados pendientes', formatMoney(deudaClientes), Icons.people),
            ],
          ),
          if (top5.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Productos más vendidos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...top5.take(5).map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_fire_department, color: AppColors.lime),
                    title: Text(e.key, style: const TextStyle(color: Colors.white)),
                    trailing: Text('${e.value.toStringAsFixed(0)} vendidos', style: const TextStyle(color: Colors.white70)),
                  ),
                )),
          ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.indigo),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
