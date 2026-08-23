import 'package:flutter/material.dart';
import '../../data/app_database.dart';
import '../../theme/app_theme.dart';

class _Slide {
  final IconData icon;
  final String titulo;
  final String texto;
  const _Slide({required this.icon, required this.titulo, required this.texto});
}

const _slides = [
  _Slide(
    icon: Icons.qr_code_scanner,
    titulo: 'Tu inventario, sin líos',
    texto: 'Agrega productos escaneando el código de barras o QR — ya no hay que escribirlo a mano, producto por producto.',
  ),
  _Slide(
    icon: Icons.sync_alt,
    titulo: 'Pago Mixto de verdad',
    texto: 'Divide el cobro entre varios métodos — efectivo, Zelle, punto — y cada parte cae en su lugar correcto al cerrar caja.',
  ),
  _Slide(
    icon: Icons.storefront,
    titulo: 'Todo tu negocio en un solo lugar',
    texto: 'Ventas, caja, clientes fiados, proveedores y reportes — funciona sin depender de internet.',
  ),
];

/// Se muestra una sola vez, antes de pedir la licencia. Marca
/// `onboarding_visto` en almacenamiento local para no repetirse.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _pagina = 0;

  Future<void> _terminar() async {
    await AppDatabase.setBool('onboarding_visto', true);
    if (mounted) widget.onFinish();
  }

  void _siguiente() {
    if (_pagina == _slides.length - 1) {
      _terminar();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esUltima = _pagina == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: esUltima
                    ? const SizedBox(height: 40)
                    : TextButton(onPressed: _terminar, child: const Text('Saltar', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600))),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _pagina = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.indigo, AppColors.indigoDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
                          ),
                          child: Icon(s.icon, color: AppColors.lime, size: 48),
                        ),
                        const SizedBox(height: 36),
                        Text(s.titulo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(s.texto, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14.5, height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final activo = i == _pagina;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: activo ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: activo ? AppColors.lime : Colors.white24, borderRadius: BorderRadius.circular(4)),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _siguiente,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(esUltima ? 'Comenzar' : 'Siguiente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
