import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../state/productos_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import 'calculadora_bultos.dart';

class ProductoFormSheet extends StatefulWidget {
  final Producto? producto;
  const ProductoFormSheet({super.key, this.producto});

  @override
  State<ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<ProductoFormSheet> {
  late final _emojiCtrl = TextEditingController(text: widget.producto?.emoji ?? '📦');
  late final _nombreCtrl = TextEditingController(text: widget.producto?.nombre ?? '');
  late final _catCtrl = TextEditingController(text: widget.producto?.categoria ?? '');
  late final _precioCtrl = TextEditingController(text: widget.producto?.precio.toString() ?? '');
  late final _costoCtrl = TextEditingController(text: widget.producto?.costo.toString() ?? '0');
  late final _stockCtrl = TextEditingController(text: widget.producto?.stock.toString() ?? '0');
  late final _stockMinCtrl = TextEditingController(text: widget.producto?.stockMin.toString() ?? '5');
  late final _margenCtrl = TextEditingController(
    text: widget.producto != null && widget.producto!.precio > 0
        ? (((widget.producto!.precio - widget.producto!.costo) / widget.producto!.precio) * 100).toStringAsFixed(0)
        : '',
  );
  late String _unidad = widget.producto?.unidad ?? 'und';
  late String? _imagen = widget.producto?.imagen;
  late final _codigoCtrl = TextEditingController(text: widget.producto?.codigo ?? '');
  bool _guardando = false;

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _nombreCtrl.dispose();
    _catCtrl.dispose();
    _precioCtrl.dispose();
    _costoCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    _margenCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escanearCodigo() async {
    final valor = await BarcodeScannerSheet.abrir(context);
    if (valor == null || !mounted) return;
    setState(() => _codigoCtrl.text = valor);
  }

  Future<void> _elegirFoto() async {
    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (archivo == null) return;
    final bytes = await File(archivo.path).readAsBytes();
    if (!mounted) return;
    setState(() => _imagen = base64Encode(bytes));
  }

  double get _costo => double.tryParse(_costoCtrl.text) ?? 0;
  double get _precio => double.tryParse(_precioCtrl.text) ?? 0;
  double get _gananciaPorUnidad => _precio - _costo;
  /// Costo + % ganancia deseado → precio de venta.
  /// Réplica exacta de calcPrecioAutomatico() de bodega-pro-v9.html
  /// (igual que CalculadoraBultos): el margen es sobre el PRECIO DE VENTA,
  /// no sobre el costo, para que el mismo % dé siempre el mismo precio
  /// sin importar dónde se cargue en la app.
  void _calcularPrecio() {
    final margen = double.tryParse(_margenCtrl.text);
    if (_costo > 0 && margen != null && margen >= 0 && margen < 100) {
      _precioCtrl.text = (_costo / (1 - margen / 100)).toStringAsFixed(2);
    }
    setState(() {});
  }

  /// Vuelca el resultado de la calculadora de bultos en el formulario.
  void _aplicarCalculo(CalculoBultos r) {
    setState(() {
      _costoCtrl.text = r.costoUnitario.toStringAsFixed(3);
      _precioCtrl.text = r.precioFinal.toStringAsFixed(2);
      _stockCtrl.text = r.totalUnidades.toStringAsFixed(0);
      _margenCtrl.text = r.margenRealPct.toStringAsFixed(0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Precio aplicado: \$${r.precioFinal.toStringAsFixed(2)} por unidad'), backgroundColor: Colors.green.shade700),
    );
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es obligatorio'), backgroundColor: Colors.redAccent));
      return;
    }
    final controller = context.read<ProductosController>();
    final datos = Producto(
      id: widget.producto?.id ?? 0,
      nombre: _nombreCtrl.text.trim(),
      emoji: _emojiCtrl.text.trim().isEmpty ? '📦' : _emojiCtrl.text.trim(),
      categoria: _catCtrl.text.trim(),
      precio: _precio,
      costo: _costo,
      stock: double.tryParse(_stockCtrl.text) ?? 0,
      stockMin: double.tryParse(_stockMinCtrl.text) ?? 5,
      unidad: _unidad,
      imagen: _imagen,
      codigo: _codigoCtrl.text.trim(),
    );
    setState(() => _guardando = true);
    if (widget.producto != null) {
      await controller.guardar(datos);
    } else {
      await controller.crear(datos);
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Guardado')]), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.producto != null;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editando ? 'Editar producto' : 'Nuevo producto', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Center(child: _FotoPicker(base64: _imagen, onTap: _elegirFoto, onQuitar: _imagen != null ? () => setState(() => _imagen = null) : null)),
              const SizedBox(height: 16),
              Row(children: [
                SizedBox(width: 70, child: TextField(controller: _emojiCtrl, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20), decoration: const InputDecoration(labelText: 'Emoji'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _nombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre *'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _catCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Categoría')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _codigoCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Código de barras / QR', hintText: 'Escanea o escribe'))),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _escanearCodigo,
                  tooltip: 'Escanear código',
                  icon: const Icon(Icons.qr_code_scanner),
                  style: IconButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _costoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Costo'), onChanged: (_) => _calcularPrecio())),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _margenCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '% ganancia', hintText: 'ej: 30'), onChanged: (_) => _calcularPrecio())),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _precioCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Precio venta *'), onChanged: (_) => setState(() {}))),
              ]),
              if (_costo > 0 && _precio > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'Ganancia: \$${_gananciaPorUnidad.toStringAsFixed(2)} por $_unidad · Margen ${(_gananciaPorUnidad / _precio * 100).toStringAsFixed(0)}% sobre PVP',
                    style: const TextStyle(color: AppColors.lime, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              CalculadoraBultos(onAplicar: _aplicarCalculo),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _stockCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stock'), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _stockMinCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stock mínimo'))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidad,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: Producto.unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unidad = v ?? 'und'),
                  ),
                ),
              ]),
              if (Producto.unidadesPeso.contains(_unidad)) ...[
                const SizedBox(height: 8),
                Text('Se vende por peso: en el punto de venta se pedirá la cantidad exacta.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(editando ? 'Guardar cambios' : 'Agregar producto', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoPicker extends StatelessWidget {
  final String? base64;
  final VoidCallback onTap;
  final VoidCallback? onQuitar;

  const _FotoPicker({required this.base64, required this.onTap, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: base64 != null ? AppColors.indigo.withValues(alpha: 0.6) : Colors.white24),
            ),
            child: base64 != null
                ? Image.memory(base64Decode(base64!), fit: BoxFit.cover)
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.white38, size: 26),
                        SizedBox(height: 2),
                        Text('Foto', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
          ),
        ),
        if (onQuitar != null)
          TextButton(
            onPressed: onQuitar,
            style: TextButton.styleFrom(minimumSize: const Size(0, 30), padding: EdgeInsets.zero),
            child: const Text('Quitar', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
