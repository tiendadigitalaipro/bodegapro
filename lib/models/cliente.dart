class Cliente {
  final int id;
  final String nombre;
  final String telefono;
  final String cedula;
  final double limite;
  final String notas;
  final double deuda;
  final DateTime? ultimaCompra;

  const Cliente({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.cedula = '',
    this.limite = 50,
    this.notas = '',
    this.deuda = 0,
    this.ultimaCompra,
  });

  double get disponible => limite - deuda;

  Cliente copyWith({
    String? nombre,
    String? telefono,
    String? cedula,
    double? limite,
    String? notas,
    double? deuda,
    DateTime? ultimaCompra,
  }) {
    return Cliente(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      cedula: cedula ?? this.cedula,
      limite: limite ?? this.limite,
      notas: notas ?? this.notas,
      deuda: deuda ?? this.deuda,
      ultimaCompra: ultimaCompra ?? this.ultimaCompra,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'cedula': cedula,
        'limite': limite,
        'notas': notas,
        'deuda': deuda,
        'ultimaCompra': ultimaCompra?.toIso8601String(),
      };

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as int,
        nombre: json['nombre'] ?? '',
        telefono: json['telefono'] ?? '',
        cedula: json['cedula'] ?? '',
        limite: (json['limite'] as num?)?.toDouble() ?? 50,
        notas: json['notas'] ?? '',
        deuda: (json['deuda'] as num?)?.toDouble() ?? 0,
        ultimaCompra: json['ultimaCompra'] != null ? DateTime.tryParse(json['ultimaCompra']) : null,
      );
}
