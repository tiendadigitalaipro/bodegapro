import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/avance.dart';
import '../../models/caja_movimiento.dart';
import '../../state/avances_controller.dart';
import '../../state/caja_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class AvancesScreen extends StatefulWidget {
  const AvancesScreen({super.key});

  @override
  State<AvancesScreen> createState() => _AvancesScreenState();
}

class _AvancesScreenState extends State<AvancesScreen> {
  final _montoCtrl = TextEditingController();
  final _comisionCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  TipoEfectivo _tipo = TipoEfectivo.usd;
  String _modalidad = '';

  @override
  void dispose() {
    _montoCtrl.dispose();
    _comisionCtrl.dispose();
    _clienteCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  double get _monto => double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _comision => double.tryParse(_comisionCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _ganancia => _monto * (_comision / 100);
  double get _total => _monto + _ganancia;
  String get _simbolo => _tipo == TipoEfectivo.usd ? '\$' : 'Bs';

  /// Al elegir modalidad se precarga su comisión configurada.
  void _elegirModalidad(String m) {
    setState(() {
      _modalidad = m;
      _comisionCtrl.text = context.read<AvancesController>().comisionDe(m).toString();
    });
  }

  Future<void> _registrar() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_monto <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Ingresa un monto válido'), backgroundColor: Colors.redAccent));
      return;
    }
    if (_modalidad.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Selecciona una modalidad de cobro'), backgroundColor: Colors.redAccent));
      return;
    }

    final avances = context.read<AvancesController>();
    final caja = context.read<CajaController>();
    final avance = await avances.registrar(
      monto: _monto,
      comisionPct: _comision,
      modalidad: _modalidad,
      tipo: _tipo,
      cliente: _clienteCtrl.text.trim(),
      referencia: _referenciaCtrl.text.trim(),
    );

    // La comisión entra a caja como ingreso, igual que en el original.
    if (caja.turnoActivo != null) {
      await caja.registrarMovimiento(
        tipo: TipoMovimiento.entrada,
        monto: avance.ganancia,
        motivo: 'Avance: ${avance.simbolo}${avance.monto.toStringAsFixed(2)} vía ${avance.modalidad}'
            '${avance.cliente.isNotEmpty ? ' - ${avance.cliente}' : ''}',
      );
    }

    _montoCtrl.clear();
    _clienteCtrl.clear();
    _referenciaCtrl.clear();
    setState(() => _modalidad = '');
    messenger.showSnackBar(SnackBar(
      content: Text('Avance registrado · comisión ${formatMoney(avance.ganancia)}'),
      backgroundColor: Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final avances = context.watch<AvancesController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _Stat('Operaciones hoy', '${avances.operacionesHoy}', Icons.swap_horiz)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Entregado hoy', formatMoney(avances.efectivoEntregadoHoy), Icons.payments)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Stat('Ganancia hoy', formatMoney(avances.gananciaHoy), Icons.trending_up)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Ganancia total', formatMoney(avances.gananciaTotal), Icons.savings)),
          ]),
          const SizedBox(height: 20),

          const Text('Nuevo avance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          SegmentedButton<TipoEfectivo>(
            segments: const [
              ButtonSegment(value: TipoEfectivo.usd, label: Text('USD')),
              ButtonSegment(value: TipoEfectivo.bs, label: Text('Bs')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 14),
          const Text('Modalidad de cobro', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Avance.modalidades.map((m) {
              final activa = m == _modalidad;
              return ChoiceChip(
                label: Text('$m · ${avances.comisionDe(m).toStringAsFixed(0)}%'),
                selected: activa,
                onSelected: (_) => _elegirModalidad(m),
                selectedColor: AppColors.indigo.withValues(alpha: 0.25),
                backgroundColor: AppColors.surfaceLight,
                labelStyle: TextStyle(color: activa ? AppColors.indigo : Colors.white70, fontSize: 12, fontWeight: activa ? FontWeight.bold : FontWeight.normal),
                side: BorderSide(color: activa ? AppColors.indigo : Colors.transparent),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Monto en efectivo ($_simbolo)'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _comisionCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: '% comisión'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _clienteCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Cliente (opcional)'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _referenciaCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Referencia (opcional)'))),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Calc('Entrega', '$_simbolo ${_monto.toStringAsFixed(2)}', Colors.white),
                _Calc('Comisión', '$_simbolo ${_ganancia.toStringAsFixed(2)}', AppColors.lime),
                _Calc('Cobra', '$_simbolo ${_total.toStringAsFixed(2)}', AppColors.indigo),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _registrar,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Registrar avance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 24),
          const Text('Historial de avances', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (avances.avances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aún no hay avances registrados.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
            )
          else
            ...avances.avances.map((a) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.indigo.withValues(alpha: 0.15),
                      child: const Icon(Icons.swap_horiz, color: AppColors.indigo, size: 18),
                    ),
                    title: Text(
                      '${a.simbolo}${a.monto.toStringAsFixed(2)} · ${a.modalidad}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${a.fecha.day}/${a.fecha.month} · ${a.comisionPct.toStringAsFixed(0)}%'
                      '${a.cliente.isNotEmpty ? ' · ${a.cliente}' : ''}'
                      '${a.referencia.isNotEmpty ? ' · ref ${a.referencia}' : ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+${a.simbolo}${a.ganancia.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white38),
                          onPressed: () => context.read<AvancesController>().eliminar(a.id),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  const _Stat(this.label, this.valor, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.indigo, size: 18),
            const SizedBox(height: 6),
            Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Calc extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _Calc(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
