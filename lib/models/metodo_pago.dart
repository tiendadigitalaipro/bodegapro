import 'package:flutter/material.dart';

enum Moneda { usd, bs, especial }

class MetodoPago {
  final String nombre;
  final IconData icon;
  final Moneda moneda;
  final bool esEfectivo;

  const MetodoPago({
    required this.nombre,
    required this.icon,
    required this.moneda,
    this.esEfectivo = false,
  });
}

/// Métodos de pago de bodega-pro-v9.html.
const List<MetodoPago> metodosPago = [
  MetodoPago(nombre: 'Efectivo \$', icon: Icons.attach_money, moneda: Moneda.usd, esEfectivo: true),
  MetodoPago(nombre: 'Zelle', icon: Icons.account_balance, moneda: Moneda.usd),
  MetodoPago(nombre: 'Binance Pay', icon: Icons.currency_bitcoin, moneda: Moneda.usd),
  MetodoPago(nombre: 'Zinli', icon: Icons.account_balance_wallet, moneda: Moneda.usd),
  MetodoPago(nombre: 'Bybit Pay', icon: Icons.currency_bitcoin, moneda: Moneda.usd),
  MetodoPago(nombre: 'Apolo Pay', icon: Icons.rocket_launch, moneda: Moneda.usd),
  MetodoPago(nombre: 'Efectivo Bs', icon: Icons.payments, moneda: Moneda.bs, esEfectivo: true),
  MetodoPago(nombre: 'Pago Móvil', icon: Icons.smartphone, moneda: Moneda.bs),
  MetodoPago(nombre: 'Punto Crédito', icon: Icons.credit_card, moneda: Moneda.bs),
  MetodoPago(nombre: 'Punto Débito', icon: Icons.credit_card, moneda: Moneda.bs),
  MetodoPago(nombre: 'Transferencia Bs', icon: Icons.swap_horiz, moneda: Moneda.bs),
  MetodoPago(nombre: 'Bio Pago', icon: Icons.fingerprint, moneda: Moneda.bs),
  MetodoPago(nombre: 'Fiado', icon: Icons.event_note, moneda: Moneda.especial),
  MetodoPago(nombre: 'Pago Mixto', icon: Icons.sync_alt, moneda: Moneda.especial),
];
