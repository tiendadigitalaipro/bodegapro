import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

/// Escáner de código de barras/QR de cámara completa. Devuelve el valor
/// escaneado por [Navigator.pop] o `null` si el usuario cancela.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();

  static Future<String?> abrir(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerSheet(), fullscreenDialog: true),
    );
  }
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _capturado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_capturado) return;
    final valor = capture.barcodes.firstOrNull?.rawValue;
    if (valor == null || valor.isEmpty) return;
    _capturado = true;
    Navigator.of(context).pop(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear código'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) => Icon(state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 48),
                    const SizedBox(height: 16),
                    const Text('No se pudo abrir la cámara', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa que Bodega Pro tenga permiso de cámara en los ajustes del teléfono, o escribe el código a mano.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(border: Border.all(color: AppColors.lime, width: 3), borderRadius: BorderRadius.circular(16)),
          ),
          const Positioned(
            bottom: 40,
            child: Text('Apunta al código de barras o QR del producto', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
