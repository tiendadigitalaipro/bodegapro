import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../services/license_service.dart';

enum EstadoLicencia { cargando, prueba, activa, bloqueada }

/// Controla el acceso a la app: NO hay periodo de prueba local automático.
/// Desde la primera apertura se exige un código (demo o PRO) generado en el
/// panel de licencias y validado contra el A2K License Engine — así cada
/// instalación queda ligada a un cliente real desde el día 1, y se puede
/// revocar o hacer seguimiento sin esperar a que se agote un cronómetro
/// local. Si ya hay una licencia guardada, se revalida contra el servidor
/// en cada arranque; si no hay conexión, se mantiene el último acceso
/// concedido (no se bloquea a un cliente que ya pagó solo por estar sin
/// internet).
class LicenseController extends ChangeNotifier {
  EstadoLicencia estado = EstadoLicencia.cargando;
  String? licenciaKey;
  String? mensajeError;
  int? diasRestantesDemo;

  Future<void> cargar() async {
    await AppDatabase.init();
    licenciaKey = AppDatabase.getJson('licencia_key') as String?;

    if (licenciaKey == null) {
      estado = EstadoLicencia.bloqueada;
      notifyListeners();
      return;
    }

    final resultado = await LicenseService.validar(licenciaKey!);
    if (resultado.valid) {
      estado = resultado.type == 'demo' ? EstadoLicencia.prueba : EstadoLicencia.activa;
      diasRestantesDemo = resultado.daysLeft;
      mensajeError = null;
    } else if (resultado.networkError) {
      estado = EstadoLicencia.activa;
    } else {
      estado = EstadoLicencia.bloqueada;
      mensajeError = resultado.reason;
    }
    notifyListeners();
  }

  Future<bool> activarLicencia(String key) async {
    final normalizada = key.trim().toUpperCase();
    final resultado = await LicenseService.validar(normalizada);
    if (resultado.valid) {
      licenciaKey = normalizada;
      await AppDatabase.setJson('licencia_key', licenciaKey);
      estado = resultado.type == 'demo' ? EstadoLicencia.prueba : EstadoLicencia.activa;
      diasRestantesDemo = resultado.daysLeft;
      mensajeError = null;
      notifyListeners();
      return true;
    }
    mensajeError = resultado.networkError
        ? 'Sin conexión a internet. Intenta de nuevo.'
        : (resultado.reason ?? 'Licencia inválida');
    notifyListeners();
    return false;
  }
}
