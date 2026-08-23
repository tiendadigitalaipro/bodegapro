/// Cuenta de cajero. Entra con usuario y contraseña, sin código de licencia,
/// y con permisos restringidos (ver [permisosBloqueados]).
class Empleado {
  /// Lo que un empleado NO puede hacer, según el original.
  static const permisosBloqueados = [
    'Editar/agregar/borrar productos',
    'Abrir/cerrar caja',
    'Reportes',
    'Proveedores',
    'Avances de efectivo',
    'Configuración',
    'Agregar/eliminar clientes',
  ];

  static const permisosPermitidos = [
    'Punto de Venta',
    'Cobrar',
    'Ver inventario',
    'Ver historial',
    'Devoluciones',
    'Dashboard',
  ];

  final int id;
  final String nombre;
  final String usuario;
  final String password;
  final bool activo;

  const Empleado({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.password,
    this.activo = true,
  });

  Empleado copyWith({String? nombre, String? usuario, String? password, bool? activo}) {
    return Empleado(
      id: id,
      nombre: nombre ?? this.nombre,
      usuario: usuario ?? this.usuario,
      password: password ?? this.password,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'usuario': usuario,
        'password': password,
        'activo': activo,
      };

  factory Empleado.fromJson(Map<String, dynamic> json) => Empleado(
        id: json['id'] as int,
        nombre: json['nombre'] ?? '',
        usuario: json['usuario'] ?? '',
        password: json['password'] ?? '',
        activo: json['activo'] ?? true,
      );
}
