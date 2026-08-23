import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../state/cart_controller.dart';
import '../../state/configuracion_controller.dart';
import '../../state/productos_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import '../../widgets/pressable_scale.dart';
import 'cart_sheet.dart';

const String _todas = 'Todas';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _categoriaActiva = _todas;
  String _busqueda = '';

  List<Producto> _filtrados(List<Producto> productos) {
    return productos.where((p) {
      final coincideCategoria = _categoriaActiva == _todas || p.categoria == _categoriaActiva;
      final coincideBusqueda = _busqueda.isEmpty || p.nombre.toLowerCase().contains(_busqueda.toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  void _abrirPesaje(Producto p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => PesajeSheet(producto: p),
    );
  }

  void _abrirCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final productosController = context.watch<ProductosController>();
    final config = context.watch<ConfiguracionController>().config;
    final categorias = [_todas, ...productosController.categorias];
    final productos = _filtrados(productosController.productos);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: const Icon(Icons.search, color: AppColors.indigo),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _busqueda = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categorias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = categorias[i];
              final activa = cat == _categoriaActiva;
              return ChoiceChip(
                label: Text(cat),
                selected: activa,
                onSelected: (_) => setState(() => _categoriaActiva = cat),
                selectedColor: AppColors.indigo.withValues(alpha: 0.25),
                backgroundColor: AppColors.surfaceLight,
                labelStyle: TextStyle(color: activa ? AppColors.indigo : Colors.white70, fontWeight: activa ? FontWeight.bold : FontWeight.normal),
                side: BorderSide(color: activa ? AppColors.indigo : Colors.transparent),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildGrid(productos, config.tasa)),
        if (cart.items.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ElevatedButton(
                onPressed: _abrirCarrito,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🛒 ${cart.items.length}', overflow: TextOverflow.ellipsis),
                    Flexible(
                      child: Text('Ver ticket — ${formatMoney(cart.total)}', overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(List<Producto> productos, double tasa) {
    if (productos.isEmpty) {
      return Center(
        child: Text('No hay productos.\nAgrégalos desde el módulo Inventario.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.95),
      itemCount: productos.length,
      itemBuilder: (context, i) {
        final p = productos[i];
        final sinStock = p.stock <= 0;
        return _ProductoCard(
          producto: p,
          tasa: tasa,
          disabled: sinStock,
          onTap: sinStock
              ? null
              : () => p.esPorPeso ? _abrirPesaje(p) : context.read<CartController>().agregarProducto(p),
        );
      },
    );
  }
}

/// Pesaje manual: el usuario escribe cuánto pesó y ve el subtotal en vivo.
/// El original leía una balanza USB por Web Serial; en móvil solo aplica
/// la entrada manual.
class PesajeSheet extends StatefulWidget {
  final Producto producto;
  const PesajeSheet({super.key, required this.producto});

  @override
  State<PesajeSheet> createState() => _PesajeSheetState();
}

class _PesajeSheetState extends State<PesajeSheet> {
  final _cantidadCtrl = TextEditingController();

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  double get _cantidad => double.tryParse(_cantidadCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _subtotal => widget.producto.precio * _cantidad;

  void _confirmar() {
    final p = widget.producto;
    if (_cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_cantidad > p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente (${p.stock} ${p.unidad})'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    context.read<CartController>().agregarPorPeso(p, _cantidad);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 6),
            Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${formatMoney(p.precio)} por ${p.unidad}  ·  quedan ${p.stock} ${p.unidad}',
                style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
            const SizedBox(height: 18),
            TextField(
              controller: _cantidadCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Cantidad (${p.unidad})',
                hintText: '0.000',
                hintStyle: const TextStyle(color: Colors.white24),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(
              _cantidad > 0 ? '= ${formatMoney(_subtotal)}' : '',
              style: const TextStyle(color: AppColors.lime, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _cantidad > 0 ? _confirmar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Agregar al carrito', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final double tasa;
  final bool disabled;
  final VoidCallback? onTap;

  const _ProductoCard({required this.producto, required this.tasa, required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = disabled ? Colors.white24 : AppColors.indigo;
    return PressableScale(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border(top: BorderSide(color: color, width: 2))),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(producto.emoji, style: const TextStyle(fontSize: 26)),
              Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(formatMoney(producto.precio), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(formatBs(producto.precio, tasa), style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 11)),
              Text(disabled ? 'Sin stock' : '${producto.esPorPeso ? '⚖️ ' : ''}${producto.stock.toStringAsFixed(producto.stock.truncateToDouble() == producto.stock ? 0 : 1)} ${producto.unidad}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
