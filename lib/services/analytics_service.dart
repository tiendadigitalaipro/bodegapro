import 'package:posthog_flutter/posthog_flutter.dart';

/// Token público del proyecto PostHog (organización A2K Digital Studio).
/// No es un secreto: es el equivalente al Measurement ID de Google Analytics,
/// diseñado para viajar dentro del bundle del cliente.
const String _posthogApiKey = 'phc_ASdyr5zx4q73MSd2UHKBMJXkDfxVkALwqgxFyAyfwiZG';
const String _posthogHost = 'https://us.posthog.com';

/// Envoltorio central de analytics para Bodega Pro. Mantiene todas las
/// llamadas a PostHog en un solo lugar para poder replicar el mismo patrón
/// en el resto del catálogo de apps.
class AnalyticsService {
  static Future<void> init() async {
    final config = PostHogConfig(_posthogApiKey)
      ..host = _posthogHost
      ..debug = false
      ..captureApplicationLifecycleEvents = true;
    await Posthog().setup(config);
    await Posthog().register('app_name', 'bodega_pro');
  }

  static Future<void> track(String event, [Map<String, Object>? properties]) {
    return Posthog().capture(eventName: event, properties: properties);
  }

  static Future<void> screen(String name) {
    return Posthog().screen(screenName: name);
  }
}
