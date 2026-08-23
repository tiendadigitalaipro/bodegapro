class AppConfig {
  final String nombre;
  final String rif;
  final String telefono;
  final double tasa;

  const AppConfig({
    this.nombre = 'Mi Bodega',
    this.rif = '',
    this.telefono = '',
    this.tasa = 40,
  });

  AppConfig copyWith({String? nombre, String? rif, String? telefono, double? tasa}) {
    return AppConfig(
      nombre: nombre ?? this.nombre,
      rif: rif ?? this.rif,
      telefono: telefono ?? this.telefono,
      tasa: tasa ?? this.tasa,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'rif': rif,
        'telefono': telefono,
        'tasa': tasa,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        nombre: json['nombre'] ?? 'Mi Bodega',
        rif: json['rif'] ?? '',
        telefono: json['telefono'] ?? '',
        tasa: (json['tasa'] as num?)?.toDouble() ?? 40,
      );
}
