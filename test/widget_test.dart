import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourvel/app.dart';

void main() {
  for (final width in [360.0, 800.0]) {
    testWidgets('configuração acessível em largura $width com texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const YourvelApp());
      expect(find.text('Yourvel'), findsOneWidget);
      expect(find.text('Configure o Firebase para começar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
