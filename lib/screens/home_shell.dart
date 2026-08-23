import 'package:flutter/material.dart';
import '../models/app_module.dart';
import '../theme/app_theme.dart';
import 'avances/avances_screen.dart';
import 'caja/caja_screen.dart';
import 'clientes/clientes_screen.dart';
import 'configuracion/configuracion_screen.dart';
import 'dashboard_screen.dart';
import 'devoluciones/devoluciones_screen.dart';
import 'historial/historial_screen.dart';
import 'ia/ia_screen.dart';
import 'inventario/inventario_screen.dart';
import 'pos/pos_screen.dart';
import 'proveedores/proveedores_screen.dart';
import 'reportes/reportes_screen.dart';

/// Mismo orden y etiquetas que la barra lateral de bodega-pro-v9.html.
final List<AppModule> appModules = [
  AppModule(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard, builder: (_) => const DashboardScreen()),
  AppModule(id: 'pos', label: 'Punto de Venta', icon: Icons.point_of_sale, builder: (_) => const PosScreen(), hasOwnFab: true),
  AppModule(id: 'inventario', label: 'Inventario', icon: Icons.inventory_2, builder: (_) => const InventarioScreen(), hasOwnFab: true),
  AppModule(id: 'historial', label: 'Historial', icon: Icons.receipt_long, builder: (_) => const HistorialScreen()),
  AppModule(id: 'devoluciones', label: 'Devoluciones', icon: Icons.undo, builder: (_) => const DevolucionesScreen()),
  AppModule(id: 'caja', label: 'Gestión de Caja', icon: Icons.account_balance_wallet, builder: (_) => const CajaScreen()),
  AppModule(id: 'avances', label: 'Avances', icon: Icons.swap_horiz, builder: (_) => const AvancesScreen()),
  AppModule(id: 'clientes', label: 'Clientes / Fiados', icon: Icons.people, builder: (_) => const ClientesScreen(), hasOwnFab: true),
  AppModule(id: 'reportes', label: 'Reportes', icon: Icons.bar_chart, builder: (_) => const ReportesScreen()),
  AppModule(id: 'ia', label: 'Asistente IA', icon: Icons.smart_toy, builder: (_) => const IaScreen(), hasOwnFab: true),
  AppModule(id: 'proveedores', label: 'Proveedores', icon: Icons.local_shipping, builder: (_) => const ProveedoresScreen(), hasOwnFab: true),
  AppModule(id: 'config', label: 'Configuración', icon: Icons.settings, builder: (_) => const ConfiguracionScreen()),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _selectModule(int index) => setState(() => _selectedIndex = index);

  void _selectModuleFromDrawer(int index) {
    _selectModule(index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = appModules[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppColors.indigo),
            const SizedBox(width: 8),
            const Text('Bodega Pro'),
            const SizedBox(width: 8),
            Expanded(child: Text(current.label, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)))),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.surface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.storefront, color: AppColors.indigo, size: 36),
                  SizedBox(height: 8),
                  Text('Bodega Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Elaborado por A2K Digital Studio', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            for (var i = 0; i < appModules.length; i++)
              ListTile(
                leading: Icon(appModules[i].icon, color: i == _selectedIndex ? AppColors.indigo : Colors.white70),
                title: Text(appModules[i].label, style: TextStyle(color: i == _selectedIndex ? AppColors.indigo : Colors.white70, fontWeight: i == _selectedIndex ? FontWeight.bold : FontWeight.normal)),
                selected: i == _selectedIndex,
                selectedTileColor: AppColors.indigo.withValues(alpha: 0.08),
                onTap: () => _selectModuleFromDrawer(i),
              ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation), child: child)),
        child: KeyedSubtree(key: ValueKey(current.id), child: current.builder(context)),
      ),
      floatingActionButton: current.hasOwnFab ? null : FloatingActionButton(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, onPressed: () => _selectModule(1), tooltip: 'Nueva venta', child: const Icon(Icons.point_of_sale)),
    );
  }
}
