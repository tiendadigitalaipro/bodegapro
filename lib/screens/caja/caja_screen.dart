import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/caja_movimiento.dart';
import '../../state/caja_controller.dart';
import '../../state/cart_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import '../../utils/resumen_caja.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  void _abrirCaja(BuildContext context) {
    final montoCtrl = TextEditingController(text: '0');
    final responsableCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apertura de caja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: responsableCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Responsable'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Monto inicial en caja (\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    final monto = double.tryParse(montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                    context.read<CajaController>().abrir(montoInicial: monto, responsable: responsableCtrl.text);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Abrir caja'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registrarMovimiento(BuildContext context, TipoMovimiento tipo) {
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tipo == TipoMovimiento.entrada ? 'Entrada de caja' : 'Salida de caja', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Monto \$'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Motivo *'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0 || motivoCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Monto y motivo son obligatorios'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              context.read<CajaController>().registrarMovimiento(tipo: tipo, monto: monto, motivo: motivoCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Registrar', style: TextStyle(color: AppColors.indigo)),
          ),
        ],
      ),
    );
  }

  void _cerrarCaja(BuildContext context, ResumenCaja resumen) {
    final montoCtrl = TextEditingController();
    final caja = context.read<CajaController>();
    final entradas = caja.movimientosDelTurno.where((m) => m.type == TipoMovimiento.entrada).fold(0.0, (s, m) => s + m.amount);
    final salidas = caja.movimientosDelTurno.where((m) => m.type == TipoMovimiento.salida).fold(0.0, (s, m) => s + m.amount);
    final esperado = caja.turnoActivo!.inicial + resumen.efectivo + entradas - salidas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cierre de caja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _FilaResumen('Apertura', formatMoney(caja.turnoActivo!.inicial)),
              _FilaResumen('Ventas efectivo', formatMoney(resumen.efectivo)),
              _FilaResumen('Ventas otros métodos', formatMoney(resumen.otros)),
              _FilaResumen('Entradas/Salidas', '+${formatMoney(entradas)} / -${formatMoney(salidas)}'),
              _FilaResumen('Esperado en caja (efectivo)', formatMoney(esperado), destacado: true),
              if (resumen.porMetodo.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Desglose por método', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(height: 4),
                _DesglosePorMetodo(porMetodo: resumen.porMetodo),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: montoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Monto contado en caja (\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    final contado = double.tryParse(montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                    context.read<CajaController>().cerrar(
                          ventasTotal: resumen.total,
                          efectivo: resumen.efectivo,
                          digital: resumen.otros,
                          credito: 0,
                          montoContado: contado,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cerrar caja'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaController>();
    final ventas = context.watch<CartController>().historialVentas;
    final resumen = caja.turnoActivo != null ? resumenCaja(ventas, caja.turnoActivo!.openAt) : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(caja.turnoActivo != null ? Icons.lock_open : Icons.lock, color: caja.turnoActivo != null ? Colors.greenAccent : Colors.white38),
                        const SizedBox(width: 8),
                        Text(
                          caja.turnoActivo != null ? 'Caja abierta — ${caja.turnoActivo!.responsable}' : 'Caja cerrada',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    if (caja.turnoActivo != null && resumen != null) ...[
                      const SizedBox(height: 16),
                      _FilaResumen('Apertura', formatMoney(caja.turnoActivo!.inicial)),
                      _FilaResumen('Ventas totales', formatMoney(resumen.total)),
                      _FilaResumen('Efectivo / Otros métodos', '${formatMoney(resumen.efectivo)} / ${formatMoney(resumen.otros)}'),
                      if (resumen.porMetodo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DesglosePorMetodo(porMetodo: resumen.porMetodo),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _registrarMovimiento(context, TipoMovimiento.entrada),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Entrada'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _registrarMovimiento(context, TipoMovimiento.salida),
                              icon: const Icon(Icons.remove, size: 16),
                              label: const Text('Salida'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: caja.turnoActivo != null ? () => _cerrarCaja(context, resumen!) : () => _abrirCaja(context),
                        child: Text(caja.turnoActivo != null ? 'Cerrar caja' : 'Abrir caja'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (caja.historialTurnos.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Historial de turnos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...caja.historialTurnos.take(10).map((t) => Card(
                    child: ListTile(
                      leading: Icon(
                        t.diff == 0 ? Icons.check_circle_outline : (t.diff > 0 ? Icons.arrow_upward : Icons.arrow_downward),
                        color: t.diff == 0 ? Colors.greenAccent : (t.diff > 0 ? Colors.blueAccent : Colors.redAccent),
                      ),
                      title: Text('${t.responsable} · ${formatMoney(t.contado)}', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${t.closeAt.day}/${t.closeAt.month}/${t.closeAt.year} · Esperado ${formatMoney(t.esperado)} · Dif. ${formatMoney(t.diff)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesglosePorMetodo extends StatelessWidget {
  final Map<String, double> porMetodo;
  const _DesglosePorMetodo({required this.porMetodo});

  @override
  Widget build(BuildContext context) {
    final entradas = porMetodo.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entradas.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entradas
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(formatMoney(e.value), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final String value;
  final bool destacado;
  const _FilaResumen(this.label, this.value, {this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: destacado ? AppColors.indigo : Colors.white, fontWeight: destacado ? FontWeight.bold : FontWeight.normal, fontSize: destacado ? 15 : 13)),
        ],
      ),
    );
  }
}
