import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_database.dart';
import 'screens/home_shell.dart';
import 'screens/licencia/licencia_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/analytics_service.dart';
import 'state/avances_controller.dart';
import 'state/caja_controller.dart';
import 'state/cart_controller.dart';
import 'state/clientes_controller.dart';
import 'state/configuracion_controller.dart';
import 'state/empleados_controller.dart';
import 'state/license_controller.dart';
import 'state/productos_controller.dart';
import 'state/proveedores_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/app_splash_skeleton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.init();
  runApp(const BodegaProApp());
}

class BodegaProApp extends StatelessWidget {
  const BodegaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductosController()..cargar()),
        ChangeNotifierProvider(create: (_) => ConfiguracionController()..cargar()),
        ChangeNotifierProvider(create: (_) => CartController()..cargar()),
        ChangeNotifierProvider(create: (_) => CajaController()..cargar()),
        ChangeNotifierProvider(create: (_) => ClientesController()..cargar()),
        ChangeNotifierProvider(create: (_) => ProveedoresController()..cargar()),
        ChangeNotifierProvider(create: (_) => AvancesController()..cargar()),
        ChangeNotifierProvider(create: (_) => EmpleadosController()..cargar()),
        ChangeNotifierProvider(create: (_) => LicenseController()..cargar()),
      ],
      child: MaterialApp(
        title: 'Bodega Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AppEntry(),
      ),
    );
  }
}

/// Decide, antes que nada, si mostrar el onboarding (solo la primera vez)
/// o pasar directo a la licencia. Mientras se lee el flag local, muestra
/// el mismo splash con skeleton que usa LicenseGate al cargar.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _mostrarOnboarding;

  @override
  void initState() {
    super.initState();
    _resolver();
  }

  Future<void> _resolver() async {
    await AppDatabase.init();
    final visto = AppDatabase.getBool('onboarding_visto') ?? false;
    if (mounted) setState(() => _mostrarOnboarding = !visto);
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarOnboarding == null) return const AppSplashSkeleton();
    if (_mostrarOnboarding == true) {
      return OnboardingScreen(onFinish: () => setState(() => _mostrarOnboarding = false));
    }
    return const LicenseGate();
  }
}

class LicenseGate extends StatelessWidget {
  const LicenseGate({super.key});

  @override
  Widget build(BuildContext context) {
    final licencia = context.watch<LicenseController>();

    switch (licencia.estado) {
      case EstadoLicencia.cargando:
        return const AppSplashSkeleton();
      case EstadoLicencia.prueba:
      case EstadoLicencia.activa:
        return const HomeShell();
      case EstadoLicencia.bloqueada:
        return const LicenciaScreen();
    }
  }
}
