import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourvel/app.dart';
import 'package:yourvel/features/travel/data/travel_repository.dart';
import 'package:yourvel/features/travel/domain/models.dart';
import 'package:yourvel/features/travel/presentation/diary_page.dart';
import 'auth_page_test.dart' show FakeAuth;

class FakeTravel extends Fake implements TravelRepository {
  int watches = 0;
  bool failFirst = false;
  @override
  Stream<List<TravelEntry>> watch() {
    watches++;
    return failFirst && watches == 1
        ? Stream.error(Exception('offline'))
        : Stream.value([]);
  }

  @override
  String newId() => 'draft';
  @override
  Future<Uint8List?> image(String path) async => null;
}

void main() {
  testWidgets('diário permite tentar novamente após erro de leitura', (
    tester,
  ) async {
    final repo = FakeTravel()..failFirst = true;
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryPage(auth: FakeAuth(), repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Criar primeira memória'), findsOneWidget);
    expect(repo.watches, 2);
  });

  testWidgets(
    'voltar do formulário confirma descarte e permite continuar editando',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionNavigator(auth: FakeAuth(), repository: FakeTravel()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova memória'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Recife');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Descartar esta memória?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(find.text('Recife'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('Seu mundo, em memórias.'), findsOneWidget);
    },
  );

  testWidgets('diário vazio comporta texto ampliado no celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryPage(auth: FakeAuth(), repository: FakeTravel()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
