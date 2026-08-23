import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cliente.dart';
import '../../models/metodo_pago.dart';
import '../../models/pago_parcial.dart';
import '../../services/analytics_service.dart';
import '../../state/cart_controller.dart';
import '../../state/clientes_controller.dart';
import '../../state/productos_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

const int _nuevoClienteSentinel = -1;

/// Métodos elegibles dentro de un pago mixto — Fiado sí puede ser una de las
/// filas (para dejar solo el resto fiado sin salir del pago mixto); el propio
/// Pago Mixto no tiene sentido como parte de su propio desglose.
final List<MetodoPago> _metodosMixto = metodosPago.where((m) => m.nombre != 'Pago Mixto').toList();

class _FilaPagoMixto {
  MetodoPago? metodo;
  final montoCtrl = TextEditingController();

  double montoUsd(double tasaCambio) {
    final valor = double.tryParse(montoCtrl.text) ?? 0;
    if (metodo?.moneda == Moneda.bs) return valor / tasaCambio;
    return valor;
  }

  void dispose() => montoCtrl.dispose();
}

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  MetodoPago? _seleccionado;
  final _recibidoCtrl = TextEditingController();
  int? _clienteId;
  bool _procesando = false;
  final List<_FilaPagoMixto> _filasMixtas = [];

  @override
  void dispose() {
    _recibidoCtrl.dispose();
    for (final f in _filasMixtas) {
      f.dispose();
    }
    super.dispose();
  }

  void _seleccionar(MetodoPago m) {
    setState(() {
      _seleccionado = m;
      if (m.nombre == 'Pago Mixto' && _filasMixtas.isEmpty) {
        _filasMixtas.addAll([_FilaPagoMixto(), _FilaPagoMixto()]);
      }
    });
  }

  void _agregarFilaMixta() => setState(() => _filasMixtas.add(_FilaPagoMixto()));

  void _quitarFilaMixta(int i) => setState(() {
        _filasMixtas[i].dispose();
        _filasMixtas.removeAt(i);
      });

  Future<void> _nuevoClienteRapido(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final creado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nuevo cliente', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre *')),
            const SizedBox(height: 12),
            TextField(controller: telCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nombreCtrl.text.trim().isNotEmpty),
            child: const Text('Crear', style: TextStyle(color: AppColors.indigo)),
          ),
        ],
      ),
    );
    if (creado != true || !context.mounted) return;
    final clientesController = context.read<ClientesController>();
    await clientesController.guardar(Cliente(id: 0, nombre: nombreCtrl.text.trim(), telefono: telCtrl.text.trim()));
    setState(() => _clienteId = clientesController.clientes.last.id);
  }

  double _asignadoMixtoUsd(double tasaCambio) => _filasMixtas.fold(0.0, (s, f) => s + f.montoUsd(tasaCambio));

  double _fiadoMixtoUsd(double tasaCambio) => _filasMixtas.where((f) => f.metodo?.nombre == 'Fiado').fold(0.0, (s, f) => s + f.montoUsd(tasaCambio));

  bool _mixtoValido(double totalUsd, double tasaCambio) {
    if (_filasMixtas.any((f) => f.metodo == null || f.montoUsd(tasaCambio) <= 0)) return false;
    return (totalUsd - _asignadoMixtoUsd(tasaCambio)).abs() < 0.01;
  }

  Future<void> _confirmar() async {
    final metodo = _seleccionado;
    if (metodo == null) return;
    final cart = context.read<CartController>();
    final esMixto = metodo.nombre == 'Pago Mixto';
    if (esMixto && !_mixtoValido(cart.total, cart.tasaCambio)) return;

    final productos = context.read<ProductosController>();
    final clientes = context.read<ClientesController>();
    final esFiado = metodo.nombre == 'Fiado';
    final montoFiadoMixto = esMixto ? _fiadoMixtoUsd(cart.tasaCambio) : 0.0;

    if ((esFiado || montoFiadoMixto > 0) && _clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un cliente para fiar'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _procesando = true);
    try {
      List<PagoParcial> pagosMixtos = const [];
      double recibidoUsd;
      if (esMixto) {
        pagosMixtos = _filasMixtas.map((f) => PagoParcial(metodo: f.metodo!.nombre, montoUsd: f.montoUsd(cart.tasaCambio))).toList();
        recibidoUsd = cart.total;
      } else if (metodo.esEfectivo) {
        final recibido = double.tryParse(_recibidoCtrl.text) ?? cart.total;
        recibidoUsd = metodo.moneda == Moneda.bs ? recibido / cart.tasaCambio : recibido;
      } else {
        recibidoUsd = cart.total;
      }

      final items = List.of(cart.items);
      final venta = await cart.confirmarVenta(metodo: metodo.nombre, recibidoUsd: recibidoUsd, pagosMixtos: pagosMixtos);
      for (final item in items) {
        await productos.ajustarStock(item.productId, -item.qty);
      }
      if (esFiado) {
        await clientes.registrarFiado(_clienteId!, venta.totalUsd);
      } else if (montoFiadoMixto > 0) {
        await clientes.registrarFiado(_clienteId!, montoFiadoMixto);
      }
      AnalyticsService.track('venta_registrada', {
        'metodo_pago': metodo.nombre,
        'total_usd': venta.totalUsd,
        'cantidad_items': items.length,
        'es_fiado': esFiado || montoFiadoMixto > 0,
        'es_mixto': esMixto,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Venta registrada'), backgroundColor: Colors.green.shade700));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Widget _clienteDropdown(BuildContext context, List<Cliente> clientes, {required String label}) {
    return DropdownButtonFormField<int>(
      initialValue: _clienteId,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: _nuevoClienteSentinel, child: Text('+ Nuevo cliente', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w600))),
        ...clientes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nombre} (debe ${formatMoney(c.deuda)})'))),
      ],
      onChanged: (v) {
        if (v == _nuevoClienteSentinel) {
          _nuevoClienteRapido(context);
        } else {
          setState(() => _clienteId = v);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final clientes = context.watch<ClientesController>().clientes;
    final esMixto = _seleccionado?.nombre == 'Pago Mixto';
    final asignado = esMixto ? _asignadoMixtoUsd(cart.tasaCambio) : 0.0;
    final faltante = cart.total - asignado;
    final mixtoTieneFiado = esMixto && _fiadoMixtoUsd(cart.tasaCambio) > 0;
    final puedeConfirmar = _seleccionado != null && !_procesando && (!esMixto || _mixtoValido(cart.total, cart.tasaCambio));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Método de pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Total: ${formatMoney(cart.total)}  ·  ${formatBs(cart.total, cart.tasaCambio)}', style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.6),
                itemCount: metodosPago.length,
                itemBuilder: (context, i) {
                  final m = metodosPago[i];
                  final activo = m == _seleccionado;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _seleccionar(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: activo ? AppColors.indigo.withValues(alpha: 0.15) : AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: activo ? AppColors.indigo : Colors.transparent)),
                      child: Row(
                        children: [
                          Icon(m.icon, color: activo ? AppColors.indigo : Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(m.nombre, style: TextStyle(color: activo ? Colors.white : Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_seleccionado?.nombre == 'Fiado') ...[
                const SizedBox(height: 16),
                _clienteDropdown(context, clientes, label: 'Cliente *'),
              ],
              if (_seleccionado?.esEfectivo == true) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _recibidoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: _seleccionado!.moneda == Moneda.bs ? 'Monto recibido (Bs)' : 'Monto recibido (\$)'),
                ),
              ],
              if (esMixto) ...[
                const SizedBox(height: 16),
                const Text('¿Con qué métodos pagó?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Cada parte se contará en su propio método al cerrar caja.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5)),
                const SizedBox(height: 10),
                ...List.generate(_filasMixtas.length, (i) => _FilaMixtaWidget(
                      fila: _filasMixtas[i],
                      onCambiar: () => setState(() {}),
                      onQuitar: _filasMixtas.length > 1 ? () => _quitarFilaMixta(i) : null,
                    )),
                TextButton.icon(onPressed: _agregarFilaMixta, icon: const Icon(Icons.add, size: 18), label: const Text('Agregar método'), style: TextButton.styleFrom(foregroundColor: AppColors.lime)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: faltante.abs() < 0.01 ? Colors.green.shade900.withValues(alpha: 0.3) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    faltante.abs() < 0.01
                        ? '✅ Asignado completo: ${formatMoney(asignado)}'
                        : faltante > 0
                            ? 'Falta asignar: ${formatMoney(faltante)}'
                            : 'Sobra: ${formatMoney(-faltante)} — ajusta los montos',
                    style: TextStyle(color: faltante.abs() < 0.01 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
                if (mixtoTieneFiado) ...[
                  const SizedBox(height: 12),
                  _clienteDropdown(context, clientes, label: 'Cliente que fía *'),
                ],
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: puedeConfirmar ? _confirmar : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _procesando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✅ Confirmar venta', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaMixtaWidget extends StatelessWidget {
  final _FilaPagoMixto fila;
  final VoidCallback onCambiar;
  final VoidCallback? onQuitar;
  const _FilaMixtaWidget({required this.fila, required this.onCambiar, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<MetodoPago>(
              initialValue: fila.metodo,
              isExpanded: true,
              dropdownColor: AppColors.surfaceLight,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Método', isDense: true),
              items: _metodosMixto.map((m) => DropdownMenuItem(value: m, child: Text(m.nombre, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                fila.metodo = v;
                onCambiar();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: fila.montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(labelText: fila.metodo?.moneda == Moneda.bs ? 'Bs' : '\$', isDense: true),
              onChanged: (_) => onCambiar(),
            ),
          ),
          if (onQuitar != null)
            IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.white38), onPressed: onQuitar, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}
