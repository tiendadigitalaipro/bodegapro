import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/proveedor.dart';
import '../../state/proveedores_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ProveedoresScreen extends StatelessWidget {
  const ProveedoresScreen({super.key});

  void _abrirFormulario(BuildContext context, {Proveedor? proveedor}) {
    final nombreCtrl = TextEditingController(text: proveedor?.nombre ?? '');
    final telCtrl = TextEditingController(text: proveedor?.telefono ?? '');
    final productoCtrl = TextEditingController(text: proveedor?.producto ?? '');
    final deudaCtrl = TextEditingController(text: proveedor != null && proveedor.deudaPendiente > 0 ? proveedor.deudaPendiente.toStringAsFixed(2) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(proveedor != null ? 'Editar proveedor' : 'Nuevo proveedor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre *')),
              const SizedBox(height: 12),
              TextField(controller: telCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 12),
              TextField(controller: productoCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Producto que suministra')),
              const SizedBox(height: 12),
              TextField(controller: deudaCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Monto de la deuda (\$)', helperText: 'Lo que le debes a este proveedor ahora mismo')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  final deuda = double.tryParse(deudaCtrl.text.trim().replaceAll(',', '.')) ?? proveedor?.deudaPendiente ?? 0;
                  context.read<ProveedoresController>().guardar(Proveedor(id: proveedor?.id ?? 0, nombre: nombreCtrl.text.trim(), telefono: telCtrl.text.trim(), producto: productoCtrl.text.trim(), deudaPendiente: deuda));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(proveedor != null ? 'Guardar cambios' : 'Agregar proveedor'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registrarPago(BuildContext context, Proveedor p) {
    final montoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Pago a ${p.nombre}', style: const TextStyle(color: Colors.white)),
        content: TextField(controller: montoCtrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Monto (\$)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0) return;
              context.read<ProveedoresController>().registrarPago(p.id, monto);
              Navigator.pop(ctx);
            },
            child: const Text('Registrar', style: TextStyle(color: AppColors.indigo)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProveedoresController>();
    final proveedores = controller.proveedores;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(heroTag: 'prov_fab', backgroundColor: AppColors.indigo, foregroundColor: Colors.white, onPressed: () => _abrirFormulario(context), child: const Icon(Icons.add)),
      body: proveedores.isEmpty
          ? Center(child: Text('No hay proveedores registrados.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Card(
                  color: AppColors.surfaceLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${proveedores.length} proveedores', style: const TextStyle(color: Colors.white70)),
                      Text('Deuda total: ${formatMoney(controller.deudaTotal)}', style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                ...proveedores.map((p) {
                  final abonado = p.historial.fold<double>(0, (s, pago) => s + pago.monto);
                  return Card(
                    child: ListTile(
                      onTap: () => _abrirFormulario(context, proveedor: p),
                      leading: CircleAvatar(backgroundColor: AppColors.indigo.withValues(alpha: 0.15), child: const Icon(Icons.local_shipping, color: AppColors.indigo, size: 18)),
                      title: Text(p.nombre, style: const TextStyle(color: Colors.white)),
                      subtitle: p.deudaPendiente > 0 || abonado > 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Debe ${formatMoney(p.deudaPendiente)}', style: TextStyle(color: p.deudaPendiente > 0 ? Colors.orangeAccent : Colors.white54, fontSize: 12)),
                                if (abonado > 0) Text('Abonado ${formatMoney(abonado)}', style: const TextStyle(color: AppColors.lime, fontSize: 11)),
                              ],
                            )
                          : const Text('Al día', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: p.deudaPendiente > 0 ? IconButton(icon: const Icon(Icons.payments, color: AppColors.lime), onPressed: () => _registrarPago(context, p)) : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
