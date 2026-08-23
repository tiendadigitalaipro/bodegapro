import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Pantalla de arranque mientras se leen los datos locales — reemplaza un
/// círculo de carga genérico por el logo de la app + barras en shimmer que
/// insinúan el contenido que ya viene en camino.
class AppSplashSkeleton extends StatelessWidget {
  const AppSplashSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.indigo, AppColors.indigoDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.storefront, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 28),
            Shimmer.fromColors(
              baseColor: AppColors.surfaceLight,
              highlightColor: AppColors.surface,
              child: Column(
                children: [
                  _barra(150),
                  const SizedBox(height: 10),
                  _barra(100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barra(double ancho) => Container(width: ancho, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)));
}
