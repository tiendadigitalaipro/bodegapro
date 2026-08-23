import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/cart_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'payment_sheet.dart';

class CartSheet extends StatefulWidget {
  const CartSheet({super.key});

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final _descuentoCtrl = TextEditingController();

  @override
  void dispose() {
    _descuentoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final sheetHeight = MediaQuery.of(context).size.height * 0.9;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.indigo),
                const SizedBox(width: 8),
                const Text('Ticket de venta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Vaciar carrito', onPressed: cart.items.isEmpty ? null : cart.vaciar),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? Center(child: Text('Selecciona productos del catálogo', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    Text('${formatMoney(item.precio)} c/u', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                                  ],
                                ),
                              ),
                              _QtyStepper(qty: item.qty, onDecrement: () => cart.cambiarCantidad(i, -1), onIncrement: () => cart.cambiarCantidad(i, 1)),
                              const SizedBox(width: 10),
                              SizedBox(width: 72, child: Text(formatMoney(item.total), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold))),
                              IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.white38), onPressed: () => cart.quitar(i)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    TextField(
                      controller: _descuentoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Descuento (\$)'),
                      onChanged: (v) => cart.setDescuento(double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow('Subtotal', formatMoney(cart.subtotal)),
                    if (cart.descuentoUsd > 0) _SummaryRow('Descuento', '-${formatMoney(cart.descuentoUsd)}', muted: true),
                    const SizedBox(height: 8),
                    _SummaryRow('TOTAL', formatMoney(cart.total), bold: true),
                    _SummaryRow('Equivalente', formatBs(cart.total, cart.tasaCambio), muted: true),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          builder: (_) => const PaymentSheet(),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text('💰 COBRAR ${formatMoney(cart.total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final double qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QtyStepper({required this.qty, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(Icons.remove, onDecrement),
        SizedBox(width: 30, child: Text(qty.truncateToDouble() == qty ? qty.toStringAsFixed(0) : qty.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
        _stepBtn(Icons.add, onIncrement),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 14, color: AppColors.indigo)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool muted;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: muted ? Colors.white38 : Colors.white70, fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: bold ? AppColors.indigo : Colors.white, fontSize: bold ? 18 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
