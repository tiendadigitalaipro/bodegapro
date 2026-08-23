import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../state/cart_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  void _abrirDevolucion(BuildContext context, Venta v) {
    String tipo = 'total';
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Procesar devolución', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  dropdownColor: AppColors.surfaceLight,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tipo de devolución'),
                  items: [
                    DropdownMenuItem(value: 'total', child: Text('Total — ${formatMoney(v.totalUsd)}')),
                    const DropdownMenuItem(value: 'parcial', child: Text('Parcial — monto específico')),
                  ],
                  onChanged: (val) => setSt(() => tipo = val ?? 'total'),
                ),
                if (tipo == 'parcial') ...[
                  const SizedBox(height: 12),
                  TextField(controller: montoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Monto a devolver (\$)')),
                ],
                const SizedBox(height: 12),
                TextField(controller: motivoCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Motivo *')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final motivo = motivoCtrl.text.trim();
                    if (motivo.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa el motivo'), backgroundColor: Colors.redAccent));
                      return;
                    }
                    final monto = tipo == 'total' ? v.totalUsd : (double.tryParse(montoCtrl.text) ?? 0);
                    if (monto <= 0 || monto > v.totalUsd) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Monto inválido'), backgroundColor: Colors.redAccent));
                      return;
                    }
                    await context.read<CartController>().registrarDevolucion(v.id, total: tipo == 'total', montoParcial: monto, motivo: motivo);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('↩️ Confirmar devolución'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<CartController>().historialVentas;

    if (ventas.isEmpty) {
      return Center(child: Text('Sin ventas registradas todavía.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: ventas.length,
      itemBuilder: (context, i) {
        final v = ventas[i];
        final devuelta = v.estadoDevolucion != EstadoDevolucion.ninguna;
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.indigo.withValues(alpha: 0.15), child: Text('#${v.id.toString().substring(v.id.toString().length - 4)}', style: const TextStyle(color: AppColors.indigo, fontSize: 9))),
            title: Text('${formatMoney(v.totalUsd)} · ${v.metodo}', style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              v.pagosMixtos.isEmpty
                  ? '${v.fecha.day}/${v.fecha.month} ${v.fecha.hour.toString().padLeft(2, '0')}:${v.fecha.minute.toString().padLeft(2, '0')} · ${v.items.length} items'
                  : '${v.fecha.day}/${v.fecha.month} ${v.fecha.hour.toString().padLeft(2, '0')}:${v.fecha.minute.toString().padLeft(2, '0')} · ${v.items.length} items\n${v.pagosMixtos.map((p) => '${p.metodo} ${formatMoney(p.montoUsd)}').join(' + ')}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: devuelta
                ? Text(v.estadoDevolucion == EstadoDevolucion.total ? 'Devuelta' : 'Dev. parcial', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))
                : IconButton(icon: const Icon(Icons.undo, color: Colors.white38), tooltip: 'Devolver', onPressed: () => _abrirDevolucion(context, v)),
          ),
        );
      },
    );
  }
}
