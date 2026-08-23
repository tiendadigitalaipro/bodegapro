import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/cart_controller.dart';
import 'comisiones_avances_card.dart';
import 'empleados_card.dart';
import '../../state/configuracion_controller.dart';
import '../../state/license_controller.dart';
import '../../theme/app_theme.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _nombreCtrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _tasaCtrl = TextEditingController();
  bool _cargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cargado) {
      _cargado = true;
      final cfg = context.read<ConfiguracionController>().config;
      _nombreCtrl.text = cfg.nombre;
      _rifCtrl.text = cfg.rif;
      _telefonoCtrl.text = cfg.telefono;
      _tasaCtrl.text = cfg.tasa.toString();
    }
  }

  Future<void> _guardar() async {
    final controller = context.read<ConfiguracionController>();
    final cartController = context.read<CartController>();
    final messenger = ScaffoldMessenger.of(context);
    final nuevaTasa = double.tryParse(_tasaCtrl.text) ?? controller.config.tasa;
    await controller.guardar(controller.config.copyWith(
      nombre: _nombreCtrl.text.trim(),
      rif: _rifCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      tasa: nuevaTasa,
    ));
    await cartController.actualizarTasa(nuevaTasa);
    if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Configuración guardada')));
  }

  @override
  Widget build(BuildContext context) {
    final licencia = context.watch<LicenseController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(licencia.estado == EstadoLicencia.activa ? Icons.verified : Icons.timer_outlined, color: licencia.estado == EstadoLicencia.activa ? Colors.greenAccent : AppColors.indigo),
                title: Text(licencia.estado == EstadoLicencia.activa ? 'Licencia activa' : 'Modo de prueba', style: const TextStyle(color: Colors.white)),
                subtitle: Text(licencia.estado == EstadoLicencia.activa ? (licencia.licenciaKey ?? '') : '${licencia.diasRestantesDemo ?? '—'} días restantes de la demo', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Datos del negocio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _nombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre del negocio'), textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    TextField(controller: _rifCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'RIF')),
                    const SizedBox(height: 16),
                    TextField(controller: _telefonoCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    TextField(controller: _tasaCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Tasa de cambio (Bs por \$)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _guardar,
                        child: const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const ComisionesAvancesCard(),
            const SizedBox(height: 24),
            const EmpleadosCard(),
            const SizedBox(height: 16),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Elaborado por A2K Digital Studio', style: TextStyle(color: Colors.white38, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
