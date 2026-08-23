import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/license_controller.dart';
import '../../theme/app_theme.dart';

const _whatsappVentas = '+58 416-4117331';

class LicenciaScreen extends StatefulWidget {
  const LicenciaScreen({super.key});

  @override
  State<LicenciaScreen> createState() => _LicenciaScreenState();
}

class _LicenciaScreenState extends State<LicenciaScreen> {
  final _keyCtrl = TextEditingController();
  bool _activando = false;

  Future<void> _activar() async {
    if (_keyCtrl.text.trim().isEmpty) return;
    setState(() => _activando = true);
    final ok = await context.read<LicenseController>().activarLicencia(_keyCtrl.text);
    if (mounted) setState(() => _activando = false);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Licencia activada'), backgroundColor: Colors.green));
    }
  }

  void _copiarNumero() {
    Clipboard.setData(const ClipboardData(text: _whatsappVentas));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Número copiado')));
  }

  @override
  Widget build(BuildContext context) {
    final licencia = context.watch<LicenseController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, color: AppColors.indigo, size: 56),
                const SizedBox(height: 12),
                const Text('Bodega Pro', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(licencia.mensajeError != null ? 'Tu licencia no está activa' : 'Ingresa tu código para empezar', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(controller: _keyCtrl, style: const TextStyle(color: Colors.white), textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código de licencia', hintText: 'PRO-BODEGA-XXXXXXXX')),
                        if (licencia.mensajeError != null) ...[const SizedBox(height: 8), Text(licencia.mensajeError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))],
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _activando ? null : _activar,
                          child: _activando ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Activar licencia'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('¿Todavía no tienes una licencia?', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: _copiarNumero, icon: const Icon(Icons.chat, size: 18), label: Text('Escríbenos al $_whatsappVentas'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.indigo, side: const BorderSide(color: AppColors.indigo))),
                const SizedBox(height: 4),
                const Text('Toca para copiar el número', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
