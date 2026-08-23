import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cliente.dart';
import '../../state/clientes_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  void _abrirFormulario(BuildContext context, {Cliente? cliente}) {
    final nombreCtrl = TextEditingController(text: cliente?.nombre ?? '');
    final telCtrl = TextEditingController(text: cliente?.telefono ?? '');
    final cedulaCtrl = TextEditingController(text: cliente?.cedula ?? '');
    final limiteCtrl = TextEditingController(text: cliente?.limite.toString() ?? '50');
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
              Text(cliente != null ? 'Editar cliente' : 'Nuevo cliente', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre *')),
              const SizedBox(height: 12),
              TextField(controller: telCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: cedulaCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Cédula'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: limiteCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Límite fiado (\$)'))),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  context.read<ClientesController>().guardar(Cliente(
                        id: cliente?.id ?? 0,
                        nombre: nombreCtrl.text.trim(),
                        telefono: telCtrl.text.trim(),
                        cedula: cedulaCtrl.text.trim(),
                        limite: double.tryParse(limiteCtrl.text) ?? 50,
                        deuda: cliente?.deuda ?? 0,
                      ));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(cliente != null ? 'Guardar cambios' : 'Agregar cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirAbono(BuildContext context, Cliente c) {
    final montoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Abono de ${c.nombre}', style: const TextStyle(color: Colors.white)),
        content: TextField(controller: montoCtrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Monto (\$)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0) return;
              context.read<ClientesController>().registrarAbono(c.id, monto);
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
    final clientes = context.watch<ClientesController>().clientes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(heroTag: 'cli_fab', backgroundColor: AppColors.indigo, foregroundColor: Colors.white, onPressed: () => _abrirFormulario(context), child: const Icon(Icons.add)),
      body: clientes.isEmpty
          ? Center(child: Text('No hay clientes registrados.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: clientes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = clientes[i];
                return Card(
                  child: ListTile(
                    onTap: () => _abrirFormulario(context, cliente: c),
                    leading: CircleAvatar(backgroundColor: AppColors.indigo.withValues(alpha: 0.15), child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold))),
                    title: Text(c.nombre, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(c.deuda > 0 ? 'Debe ${formatMoney(c.deuda)} de ${formatMoney(c.limite)}' : 'Al día', style: TextStyle(color: c.deuda > 0 ? Colors.orangeAccent : Colors.white54, fontSize: 12)),
                    trailing: c.deuda > 0
                        ? IconButton(icon: const Icon(Icons.payments, color: AppColors.lime), tooltip: 'Registrar abono', onPressed: () => _abrirAbono(context, c))
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
