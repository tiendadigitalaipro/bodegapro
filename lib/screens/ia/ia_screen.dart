import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/caja_movimiento.dart';
import '../../state/avances_controller.dart';
import '../../state/caja_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/clientes_controller.dart';
import '../../state/productos_controller.dart';
import '../../state/proveedores_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

enum _Consulta { inventario, ventas, deudores, topProductos, caja, proveedores, resumen }

class _Mensaje {
  final String texto;
  final bool esUsuario;
  const _Mensaje(this.texto, {this.esUsuario = false});
}

/// Asistente que responde con los datos locales de la app. No hace ninguna
/// llamada de red — todo se calcula sobre los controladores ya cargados.
class IaScreen extends StatefulWidget {
  const IaScreen({super.key});

  @override
  State<IaScreen> createState() => _IaScreenState();
}

class _IaScreenState extends State<IaScreen> {
  final _preguntaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Mensaje> _mensajes = [
    const _Mensaje('Hola 👋 Soy tu asistente de bodega. Pregúntame por tu inventario, ventas, fiados, caja o proveedores — o toca uno de los botones de abajo.'),
  ];

  @override
  void dispose() {
    _preguntaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _responder(String respuesta, {String? pregunta}) {
    setState(() {
      if (pregunta != null) _mensajes.add(_Mensaje(pregunta, esUsuario: true));
      _mensajes.add(_Mensaje(respuesta));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      }
    });
  }

  bool _esHoy(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  String _calcular(_Consulta consulta) {
    final productos = context.read<ProductosController>();
    final ventas = context.read<CartController>().historialVentas;
    final clientes = context.read<ClientesController>().clientes;
    final caja = context.read<CajaController>();
    final proveedores = context.read<ProveedoresController>();
    final avances = context.read<AvancesController>();

    switch (consulta) {
      case _Consulta.inventario:
        final bajos = productos.stockBajo;
        if (productos.productos.isEmpty) return 'Todavía no tienes productos cargados en el inventario.';
        if (bajos.isEmpty) return '✅ Ningún producto está por debajo de su stock mínimo. Tienes ${productos.productos.length} productos cargados.';
        final lista = bajos.take(10).map((p) => '• ${p.nombre}: ${p.stock.toStringAsFixed(p.stock.truncateToDouble() == p.stock ? 0 : 2)} ${p.unidad} (mínimo ${p.stockMin.toStringAsFixed(0)})').join('\n');
        return '⚠️ ${bajos.length} producto(s) en stock crítico:\n$lista${bajos.length > 10 ? '\n… y ${bajos.length - 10} más.' : ''}';

      case _Consulta.ventas:
        final hoy = ventas.where((v) => _esHoy(v.fecha)).toList();
        if (hoy.isEmpty) return 'Hoy todavía no has registrado ventas.';
        final total = hoy.fold<double>(0, (s, v) => s + v.totalUsd);
        final promedio = total / hoy.length;
        return '🛒 Hoy llevas ${hoy.length} venta(s) por ${formatMoney(total)}.\nTicket promedio: ${formatMoney(promedio)}.';

      case _Consulta.deudores:
        final deudores = clientes.where((c) => c.deuda > 0).toList()..sort((a, b) => b.deuda.compareTo(a.deuda));
        if (deudores.isEmpty) return '✅ Ningún cliente tiene fiado pendiente.';
        final total = deudores.fold<double>(0, (s, c) => s + c.deuda);
        final lista = deudores.take(10).map((c) => '• ${c.nombre}: ${formatMoney(c.deuda)}').join('\n');
        return '📋 ${deudores.length} cliente(s) deben ${formatMoney(total)} en total:\n$lista${deudores.length > 10 ? '\n… y ${deudores.length - 10} más.' : ''}';

      case _Consulta.topProductos:
        if (ventas.isEmpty) return 'Todavía no hay ventas para calcular los más vendidos.';
        final porProducto = <String, double>{};
        for (final v in ventas) {
          for (final i in v.items) {
            porProducto[i.nombre] = (porProducto[i.nombre] ?? 0) + i.qty;
          }
        }
        final top = porProducto.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final lista = top.take(5).map((e) => '• ${e.key}: ${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 2)} vendidos').join('\n');
        return '🔥 Tus productos más vendidos:\n$lista';

      case _Consulta.caja:
        final turno = caja.turnoActivo;
        if (turno == null) return '🔒 La caja está cerrada. Ábrela desde Gestión de Caja para empezar el turno.';
        final movs = caja.movimientosDelTurno;
        final entradas = movs.where((m) => m.type == TipoMovimiento.entrada).fold<double>(0, (s, m) => s + m.amount);
        final salidas = movs.where((m) => m.type == TipoMovimiento.salida).fold<double>(0, (s, m) => s + m.amount);
        return '🏦 Caja abierta por ${turno.responsable}.\nMonto inicial: ${formatMoney(turno.inicial)}\nEntradas: ${formatMoney(entradas)}\nSalidas: ${formatMoney(salidas)}\nEsperado en caja: ${formatMoney(turno.inicial + entradas - salidas)}';

      case _Consulta.proveedores:
        final conDeuda = proveedores.proveedores.where((p) => p.deudaPendiente > 0).toList()..sort((a, b) => b.deudaPendiente.compareTo(a.deudaPendiente));
        if (conDeuda.isEmpty) return '✅ No tienes deudas pendientes con proveedores.';
        final lista = conDeuda.take(10).map((p) => '• ${p.nombre}: ${formatMoney(p.deudaPendiente)}').join('\n');
        return '🏭 Debes ${formatMoney(proveedores.deudaTotal)} a ${conDeuda.length} proveedor(es):\n$lista';

      case _Consulta.resumen:
        final hoy = ventas.where((v) => _esHoy(v.fecha)).toList();
        final totalHoy = hoy.fold<double>(0, (s, v) => s + v.totalUsd);
        final deuda = clientes.fold<double>(0, (s, c) => s + c.deuda);
        return '📊 Resumen de hoy\n'
            '• Ventas: ${hoy.length} por ${formatMoney(totalHoy)}\n'
            '• Ganancia por avances: ${formatMoney(avances.gananciaHoy)}\n'
            '• Stock crítico: ${productos.stockBajo.length} producto(s)\n'
            '• Fiados por cobrar: ${formatMoney(deuda)}\n'
            '• Deuda a proveedores: ${formatMoney(proveedores.deudaTotal)}\n'
            '• Caja: ${caja.turnoActivo != null ? 'abierta' : 'cerrada'}';
    }
  }

  /// Sin backend de IA: se busca la intención por palabras clave sobre las
  /// mismas consultas locales.
  void _preguntaLibre() {
    final texto = _preguntaCtrl.text.trim();
    if (texto.isEmpty) return;
    final t = texto.toLowerCase();
    _preguntaCtrl.clear();

    _Consulta? consulta;
    if (t.contains('inventario') || t.contains('stock') || t.contains('acab') || t.contains('falta')) {
      consulta = _Consulta.inventario;
    } else if (t.contains('vent') || t.contains('hoy') || t.contains('vendi')) {
      consulta = _Consulta.ventas;
    } else if (t.contains('deb') || t.contains('fiad') || t.contains('deudor') || t.contains('cobrar')) {
      consulta = _Consulta.deudores;
    } else if (t.contains('top') || t.contains('más vendido') || t.contains('mas vendido') || t.contains('popular')) {
      consulta = _Consulta.topProductos;
    } else if (t.contains('caja') || t.contains('turno')) {
      consulta = _Consulta.caja;
    } else if (t.contains('proveedor')) {
      consulta = _Consulta.proveedores;
    } else if (t.contains('resumen') || t.contains('general') || t.contains('cómo va') || t.contains('como va')) {
      consulta = _Consulta.resumen;
    }

    if (consulta == null) {
      _responder(
        'No entendí esa pregunta 🤔 Puedo ayudarte con: inventario crítico, ventas de hoy, deudores, productos más vendidos, estado de caja, deudas con proveedores o un resumen general.',
        pregunta: texto,
      );
    } else {
      _responder(_calcular(consulta), pregunta: texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _mensajes.length,
            itemBuilder: (context, i) => _Burbuja(mensaje: _mensajes[i]),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('📦 Inventario crítico', _Consulta.inventario),
              _chip('🛒 Ventas de hoy', _Consulta.ventas),
              _chip('📋 Deudores', _Consulta.deudores),
              _chip('🔥 Top productos', _Consulta.topProductos),
              _chip('🏦 Estado de caja', _Consulta.caja),
              _chip('🏭 Deudas proveedores', _Consulta.proveedores),
              _chip('📊 Resumen general', _Consulta.resumen),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _preguntaCtrl,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _preguntaLibre(),
                    decoration: InputDecoration(
                      hintText: 'Pregunta sobre tu bodega...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _preguntaLibre,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Icon(Icons.send, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, _Consulta consulta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.surfaceLight,
        labelStyle: const TextStyle(color: Colors.white70),
        side: BorderSide(color: AppColors.indigo.withValues(alpha: 0.4)),
        onPressed: () => _responder(_calcular(consulta), pregunta: label),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final _Mensaje mensaje;
  const _Burbuja({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.indigo : AppColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(esUsuario ? 12 : 2),
            bottomRight: Radius.circular(esUsuario ? 2 : 12),
          ),
        ),
        child: Text(
          mensaje.texto,
          style: TextStyle(color: esUsuario ? Colors.white : Colors.white.withValues(alpha: 0.92), fontSize: 13.5, height: 1.45),
        ),
      ),
    );
  }
}
