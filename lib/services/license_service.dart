import 'dart:convert';
import 'package:http/http.dart' as http;

/// Conecta con el A2K License Engine (Cloudflare Worker) compartido por
/// todos los productos de A2K Digital Studio. Bodega Pro usa el
/// producto 'bodega', ya registrado en el panel de licencias.
class LicenseResult {
  final bool valid;
  final String? reason;
  final bool networkError;
  final String? type;
  final int? daysLeft;
  final String? cliente;

  const LicenseResult({
    required this.valid,
    this.reason,
    this.networkError = false,
    this.type,
    this.daysLeft,
    this.cliente,
  });
}

class LicenseService {
  static const _baseUrl = 'https://a2k-license-engine.shoppingelectronics3112.workers.dev';
  static const product = 'bodega';

  /// Cliente HTTP inyectable — en producción es un `http.Client()` real;
  /// los tests lo reemplazan por un `MockClient` para no depender de
  /// internet ni del servidor real.
  static http.Client client = http.Client();

  static Future<LicenseResult> validar(String key) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/validar?key=${Uri.encodeQueryComponent(key)}&product=$product',
      );
      final resp = await client.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        return const LicenseResult(valid: false, reason: 'Error del servidor');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return LicenseResult(
        valid: data['valid'] == true,
        reason: data['reason'] as String?,
        type: data['type'] as String?,
        daysLeft: data['daysLeft'] as int?,
        cliente: data['cliente'] as String?,
      );
    } catch (_) {
      return const LicenseResult(valid: false, networkError: true, reason: 'Sin conexión a internet');
    }
  }
}
