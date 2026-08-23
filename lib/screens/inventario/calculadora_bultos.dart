import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Resultado de la calculadora de compra por bultos.
class CalculoBultos {
  final double costoUnitario;
  final double precioFinal;
  final double totalUnidades;
  final double gananciaUnitaria;
  final double margenRealPct;
  final double gananciaTotal;

  const CalculoBultos({
    required this.costoUnitario,
    required this.precioFinal,
    required this.totalUnidades,
    required this.gananciaUnitaria,
    required this.margenRealPct,
    required this.gananciaTotal,
  });

  double get reinversion => gananciaTotal * 0.50;
  double get gastos => gananciaTotal * 0.30;
  double get gananciaNeta => gananciaTotal * 0.20;

  /// Réplica exacta de calcPrecioAutomatico() de bodega-pro-v9.html.
  /// OJO: el margen es sobre el PRECIO DE VENTA, no sobre el costo —
  /// `precio = costo / (1 - pct/100)` — por eso el % pedido y el margen
  /// real coinciden sobre el PVP.
  static CalculoBultos? calcular({
    required double costoBulto,
    required double unidadesPorBulto,
    required double cantidadBultos,
    required double gananciaPct,
    required bool conIva,
  }) {
    if (costoBulto <= 0 || unidadesPorBulto <= 0) return null;
    if (gananciaPct >= 100) return null;

    final bultos = cantidadBultos <= 0 ? 1.0 : cantidadBultos;
    final totalUnidades = unidadesPorBulto * bultos;
    final costoUnit = (costoBulto * bultos) / totalUnidades;

    final precioBase = gananciaPct > 0 ? costoUnit / (1 - (gananciaPct / 100)) : costoUnit;
    final precioFinal = conIva ? precioBase * 1.16 : precioBase;

    final gananciaUnit = precioFinal - costoUnit;
    final margenReal = precioFinal > 0 ? (gananciaUnit / precioFinal) * 100 : 0.0;

    return CalculoBultos(
      costoUnitario: costoUnit,
      precioFinal: precioFinal,
      totalUnidades: totalUnidades,
      gananciaUnitaria: gananciaUnit,
      margenRealPct: margenReal,
      gananciaTotal: gananciaUnit * totalUnidades,
    );
  }
}

/// Calculadora de compra por bultos: del costo del bulto saca el costo
/// unitario, el precio de venta y el reparto 50/30/20 de la ganancia.
class CalculadoraBultos extends StatefulWidget {
  final void Function(CalculoBultos resultado) onAplicar;
  const CalculadoraBultos({super.key, required this.onAplicar});

  @override
  State<CalculadoraBultos> createState() => _CalculadoraBultosState();
}

class _CalculadoraBultosState extends State<CalculadoraBultos> {
  final _costoBultoCtrl = TextEditingController();
  final _unidadesCtrl = TextEditingController();
  final _bultosCtrl = TextEditingController(text: '1');
  final _pctCtrl = TextEditingController();
  bool _conIva = false;

  @override
  void dispose() {
    _costoBultoCtrl.dispose();
    _unidadesCtrl.dispose();
    _bultosCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  CalculoBultos? get _resultado => CalculoBultos.calcular(
        costoBulto: _num(_costoBultoCtrl),
        unidadesPorBulto: _num(_unidadesCtrl),
        cantidadBultos: _num(_bultosCtrl),
        gananciaPct: _num(_pctCtrl),
        conIva: _conIva,
      );

  void _setPct(int pct) {
    _pctCtrl.text = '$pct';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    final excedeMargen = _num(_pctCtrl) >= 100;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: const Text('🏭 Calculadora de compra por bultos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Del costo del bulto saca costo unitario, precio y reparto 50/30/20', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5)),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _costoBultoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Costo del bulto'), onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _unidadesCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Uds. por bulto'), onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _bultosCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Cantidad de bultos'), onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Total unidades'),
                child: Text(r != null ? r.totalUnidades.toStringAsFixed(0) : '—', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _pctCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '% ganancia deseada (sobre el precio de venta)',
              errorText: excedeMargen ? 'El margen no puede ser 100% o más' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [15, 20, 30, 40].map((p) {
              final activo = _num(_pctCtrl) == p;
              return ChoiceChip(
                label: Text('$p%'),
                selected: activo,
                onSelected: (_) => _setPct(p),
                selectedColor: AppColors.indigo.withValues(alpha: 0.25),
                backgroundColor: AppColors.surfaceLight,
                labelStyle: TextStyle(color: activo ? AppColors.indigo : Colors.white70, fontSize: 12),
                side: BorderSide(color: activo ? AppColors.indigo : Colors.transparent),
              );
            }).toList(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Agregar IVA 16% al precio', style: TextStyle(color: Colors.white70, fontSize: 13)),
            value: _conIva,
            activeThumbColor: AppColors.indigo,
            onChanged: (v) => setState(() => _conIva = v),
          ),
          if (r != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Res('Costo/Unidad', '\$${r.costoUnitario.toStringAsFixed(3)}', Colors.white),
                      _Res('+Ganancia', '\$${r.gananciaUnitaria.toStringAsFixed(3)}${_conIva ? ' +IVA' : ''}', AppColors.lime),
                      _Res('Precio Venta', '\$${r.precioFinal.toStringAsFixed(2)}', AppColors.indigo),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${r.margenRealPct.toStringAsFixed(1)}% sobre PVP',
                    style: TextStyle(
                      color: r.margenRealPct >= 25 ? AppColors.lime : (r.margenRealPct >= 15 ? Colors.orangeAccent : Colors.redAccent),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('📊 Fórmula 50/30/20 (por bulto) · ganancia total \$${r.gananciaTotal.toStringAsFixed(2)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _SplitBox('♻️ 50% Reinversión', r.reinversion, Colors.greenAccent)),
              const SizedBox(width: 8),
              Expanded(child: _SplitBox('💸 30% Gastos', r.gastos, Colors.redAccent)),
              const SizedBox(width: 8),
              Expanded(child: _SplitBox('💰 20% Ganancia', r.gananciaNeta, Colors.lightBlueAccent)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => widget.onAplicar(r),
                child: const Text('✅ Aplicar este precio al producto'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Res extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _Res(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 3),
        Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _SplitBox extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;
  const _SplitBox(this.label, this.monto, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text('\$${monto.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
        ],
      ),
    );
  }
}
