import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../state/configuracion_controller.dart';
import '../../state/productos_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'producto_form_sheet.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  bool _modoEtiquetas = false;
  final Set<int> _seleccionados = {};

  void _abrirFormulario(BuildContext context, {Producto? producto}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => ChangeNotifierProvider.value(value: context.read<ProductosController>(), child: ProductoFormSheet(producto: producto)),
    );
  }

  void _confirmarEliminar(BuildContext context, Producto p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar producto', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${p.nombre}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () { context.read<ProductosController>().eliminar(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _copiarEtiquetas(List<Producto> productos) {
    final seleccionados = productos.where((p) => _seleccionados.contains(p.id));
    final texto = seleccionados.map((p) => '${p.emoji} ${p.nombre}\n${formatMoney(p.precio)} / ${p.unidad}\n${'-' * 24}').join('\n');
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_seleccionados.length} etiquetas copiadas — pégalas en tu app de impresión'), backgroundColor: Colors.green.shade700));
    setState(() { _modoEtiquetas = false; _seleccionados.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductosController>().productos;
    final tasa = context.watch<ConfiguracionController>().config.tasa;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_modoEtiquetas ? '${_seleccionados.length} seleccionados' : 'Inventario', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() { _modoEtiquetas = !_modoEtiquetas; _seleccionados.clear(); }),
            icon: Icon(_modoEtiquetas ? Icons.close : Icons.label, color: AppColors.indigo),
            label: Text(_modoEtiquetas ? 'Cancelar' : 'Etiquetas', style: const TextStyle(color: AppColors.indigo)),
          ),
        ],
      ),
      floatingActionButton: _modoEtiquetas
          ? (_seleccionados.isEmpty ? null : FloatingActionButton.extended(heroTag: 'inv_fab', onPressed: () => _copiarEtiquetas(productos), icon: const Icon(Icons.copy), label: const Text('Copiar')))
          : FloatingActionButton(heroTag: 'inv_fab', backgroundColor: AppColors.indigo, foregroundColor: Colors.white, onPressed: () => _abrirFormulario(context), child: const Icon(Icons.add)),
      body: productos.isEmpty
          ? Center(child: Text('No hay productos.\nToca + para agregar el primero.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: productos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = productos[i];
                if (_modoEtiquetas) {
                  final activo = _seleccionados.contains(p.id);
                  return Card(
                    child: CheckboxListTile(
                      value: activo,
                      activeColor: AppColors.indigo,
                      onChanged: (_) => setState(() => activo ? _seleccionados.remove(p.id) : _seleccionados.add(p.id)),
                      title: Text('${p.emoji} ${p.nombre}', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(formatMoney(p.precio), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  );
                }
                return Card(
                  child: ListTile(
                    onTap: () => _abrirFormulario(context, producto: p),
                    leading: p.imagen != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(base64Decode(p.imagen!), width: 40, height: 40, fit: BoxFit.cover),
                          )
                        : CircleAvatar(backgroundColor: AppColors.indigo.withValues(alpha: 0.15), child: Text(p.emoji, style: const TextStyle(fontSize: 16))),
                    title: Text(p.nombre, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${p.categoria.isNotEmpty ? '${p.categoria} · ' : ''}Stock: ${p.stock.toStringAsFixed(0)} ${p.unidad}', style: TextStyle(color: p.stockBajo ? Colors.orangeAccent : Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatMoney(p.precio), style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold)),
                            Text(formatBs(p.precio, tasa), style: const TextStyle(color: AppColors.lime, fontSize: 11)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white38), onPressed: () => _confirmarEliminar(context, p)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
