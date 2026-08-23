class CartItem {
  final int productId;
  final String nombre;
  final String emoji;
  final double precio;
  final double qty;
  final bool esPorPeso;
  final String unidad;

  const CartItem({
    required this.productId,
    required this.nombre,
    required this.emoji,
    required this.precio,
    this.qty = 1,
    this.esPorPeso = false,
    this.unidad = 'und',
  });

  double get total => precio * qty;

  String get _qtyTexto => qty == qty.truncateToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(3);

  /// En productos por peso la línea lleva la cantidad pesada, p. ej.
  /// "Arroz (2.500 kg)". Se calcula en vez de guardarse dentro del nombre
  /// para que siga siendo correcta si se edita la cantidad desde el carrito.
  String get etiqueta => esPorPeso ? '$nombre ($_qtyTexto $unidad)' : nombre;

  CartItem copyWith({double? qty}) => CartItem(
        productId: productId,
        nombre: nombre,
        emoji: emoji,
        precio: precio,
        qty: qty ?? this.qty,
        esPorPeso: esPorPeso,
        unidad: unidad,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'nombre': nombre,
        'emoji': emoji,
        'precio': precio,
        'qty': qty,
        'esPorPeso': esPorPeso,
        'unidad': unidad,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as int,
        nombre: json['nombre'] ?? '',
        emoji: json['emoji'] ?? '📦',
        precio: (json['precio'] as num?)?.toDouble() ?? 0,
        qty: (json['qty'] as num?)?.toDouble() ?? 1,
        esPorPeso: json['esPorPeso'] == true,
        unidad: json['unidad'] ?? 'und',
      );
}
