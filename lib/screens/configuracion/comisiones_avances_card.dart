import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/avance.dart';
import '../../state/avances_controller.dart';
import '../../theme/app_theme.dart';

/// Comisión por defecto de cada modalidad de avance de efectivo.
/// Equivale a guardarComisionesAvances() del original.
class ComisionesAvancesCard extends StatefulWidget {
  const ComisionesAvancesCard({super.key});

  @override
  State<ComisionesAvancesCard> createState() => _ComisionesAvancesCardState();
}

class _ComisionesAvancesCardState extends State<ComisionesAvancesCard> {
  final Map<String, TextEditingController> _ctrls = {};
  bool _cargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cargado) return;
    _cargado = true;
    final avances = context.read<AvancesController>();
    for (final m in Avance.modalidades) {
      _ctrls[m] = TextEditingController(text: avances.comisionDe(m).toStringAsFixed(0));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final messenger = ScaffoldMessenger.of(context);
    final nuevas = <String, double>{};
    for (final entry in _ctrls.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null && v >= 0) nuevas[entry.key] = v;
    }
    await context.read<AvancesController>().guardarComisiones(nuevas);
    if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Comisiones de avances guardadas')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💵 Comisiones de avances', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Se aplican solas al elegir la modalidad de cobro en Avances.', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...Avance.modalidades.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(m, style: const TextStyle(color: Colors.white70, fontSize: 13.5))),
                          SizedBox(
                            width: 92,
                            child: TextField(
                              controller: _ctrls[m],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(suffixText: '%', isDense: true),
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _guardar,
                    child: const Text('Guardar comisiones'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
