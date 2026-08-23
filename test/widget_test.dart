import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodegapro/data/app_database.dart';
import 'package:bodegapro/main.dart';
import 'package:bodegapro/services/license_service.dart';

void main() {
  final clienteOriginal = LicenseService.client;

  setUp(() {
    AppDatabase.resetForTest();
  });

  tearDown(() {
    LicenseService.client = clienteOriginal;
  });

  testWidgets('Sin licencia guardada, pide un código en vez de dar acceso libre', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'bodega_onboarding_visto': true});

    await tester.pumpWidget(const BodegaProApp());
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu código para empezar'), findsOneWidget);
  });

  testWidgets('Con licencia PRO guardada, entra directo al dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'bodega_onboarding_visto': true, 'bodega_licencia_key': '"PRO-TEST-0000"'});
    LicenseService.client = MockClient((request) async => http.Response(jsonEncode({'valid': true, 'type': 'pro'}), 200));

    await tester.pumpWidget(const BodegaProApp());
    await tester.pumpAndSettle();

    expect(find.text('Bodega Pro'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Primera vez que se abre la app, muestra el onboarding antes de pedir licencia', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BodegaProApp());
    await tester.pumpAndSettle();

    expect(find.text('Tu inventario, sin líos'), findsOneWidget);
    expect(find.text('Ingresa tu código para empezar'), findsNothing);
  });

  testWidgets('Saltar el onboarding lleva directo a pedir licencia y no vuelve a aparecer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BodegaProApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu código para empezar'), findsOneWidget);
    expect(AppDatabase.getBool('onboarding_visto'), isTrue);
  });
}
