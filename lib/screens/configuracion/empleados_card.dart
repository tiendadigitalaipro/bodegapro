import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/empleado.dart';
import '../../state/empleados_controller.dart';
import '../../theme/app_theme.dart';

/// Cuentas de cajero. En el original vive dentro de Configuración
/// (#card-empleados), no como página propia del menú.
class EmpleadosCard extends StatelessWidget {
  const EmpleadosCard({super.key});

  void _nuevoEmpleado(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final usuarioCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final controller = context.read<EmpleadosController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nuevo empleado', style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre *'), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: usuarioCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Usuario *')),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Contraseña *')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(ctx);
              if (nombreCtrl.text.trim().isEmpty || usuarioCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                messenger.showSnackBar(const SnackBar(content: Text('Completa nombre, usuario y contraseña'), backgroundColor: Colors.redAccent));
                return;
              }
              if (controller.usuarioExiste(usuarioCtrl.text)) {
                messenger.showSnackBar(const SnackBar(content: Text('Ese usuario ya existe'), backgroundColor: Colors.redAccent));
                return;
              }
              await controller.crear(nombre: nombreCtrl.text, usuario: usuarioCtrl.text, password: passCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empleados = context.watch<EmpleadosController>().empleados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('👥 Usuarios y empleados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            TextButton.icon(
              onPressed: () => _nuevoEmpleado(context),
              icon: const Icon(Icons.add, size: 18, color: AppColors.indigo),
              label: const Text('Nuevo', style: TextStyle(color: AppColors.indigo)),
            ),
          ],
        ),
        Text('Tus cajeros entran con usuario y contraseña, sin el código de licencia.', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (empleados.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text('Sin empleados registrados aún', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5))),
                  )
                else
                  ...empleados.map((e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: (e.activo ? AppColors.indigo : Colors.white24).withValues(alpha: 0.15),
                          child: Icon(Icons.person, size: 18, color: e.activo ? AppColors.indigo : Colors.white38),
                        ),
                        title: Text(e.nombre, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text('@${e.usuario}${e.activo ? '' : ' · inactivo'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: e.activo,
                              activeThumbColor: AppColors.indigo,
                              onChanged: (_) => context.read<EmpleadosController>().alternarActivo(e.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white38),
                              onPressed: () => context.read<EmpleadosController>().eliminar(e.id),
                            ),
                          ],
                        ),
                      )),
                const Divider(height: 24, color: Colors.white12),
                const Text('🔒 Restricciones del empleado', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Text('✅ Permitido: ${Empleado.permisosPermitidos.join(' · ')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11.5, height: 1.5)),
                const SizedBox(height: 6),
                Text('🚫 Bloqueado: ${Empleado.permisosBloqueados.join(' · ')}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11.5, height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
