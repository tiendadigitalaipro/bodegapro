import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Capa de persistencia local — equivalente al helper `DB` de
/// bodega-pro-v9.html, que guardaba todo en localStorage
/// con prefijo `bodega_`.
class AppDatabase {
  static const _prefix = 'bodega_';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Limpia la instancia cacheada de SharedPreferences. Solo para tests:
  /// sin esto, `SharedPreferences.setMockInitialValues` de un test
  /// posterior no tiene efecto porque `_prefs` ya quedó fijado por un
  /// test anterior en el mismo archivo.
  @visibleForTesting
  static void resetForTest() {
    _prefs = null;
  }

  static Future<void> setJson(String key, dynamic value) async {
    await init();
    await _prefs!.setString(_prefix + key, jsonEncode(value));
  }

  static dynamic getJson(String key) {
    final raw = _prefs?.getString(_prefix + key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<void> remove(String key) async {
    await init();
    await _prefs!.remove(_prefix + key);
  }

  static Future<void> setDouble(String key, double value) async {
    await init();
    await _prefs!.setDouble(_prefix + key, value);
  }

  static double? getDouble(String key) => _prefs?.getDouble(_prefix + key);

  static Future<void> setInt(String key, int value) async {
    await init();
    await _prefs!.setInt(_prefix + key, value);
  }

  static int? getInt(String key) => _prefs?.getInt(_prefix + key);

  static Future<void> setBool(String key, bool value) async {
    await init();
    await _prefs!.setBool(_prefix + key, value);
  }

  static bool? getBool(String key) => _prefs?.getBool(_prefix + key);
}
