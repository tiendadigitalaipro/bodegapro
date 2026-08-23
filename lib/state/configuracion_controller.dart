import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/app_config.dart';

class ConfiguracionController extends ChangeNotifier {
  AppConfig config = const AppConfig();

  Future<void> cargar() async {
    await AppDatabase.init();
    final json = AppDatabase.getJson('config') as Map<String, dynamic>?;
    config = json != null ? AppConfig.fromJson(json) : const AppConfig();
    notifyListeners();
  }

  Future<void> guardar(AppConfig nuevo) async {
    config = nuevo;
    await AppDatabase.setJson('config', config.toJson());
    notifyListeners();
  }
}
