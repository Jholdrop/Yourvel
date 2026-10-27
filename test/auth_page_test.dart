import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourvel/features/auth/auth_page.dart';
import 'package:yourvel/features/auth/auth_repository.dart';

class UnusedFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuth extends AuthRepository {
  FakeAuth() : super(UnusedFirebaseAuth());
  int calls = 0;
  Completer<void>? pending;
  @override
  Future<void> login(String email, String password) async {
    calls++;
    await pending?.future;
  }
}

void main() {
  testWidgets('não envia login inválido e bloqueia envios simultâneos', (
    tester,
  ) async {
    final auth = FakeAuth();
    await tester.pumpWidget(MaterialApp(home: AuthPage(auth: auth)));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um email válido.'), findsOneWidget);
    expect(auth.calls, 0);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'viajante@teste.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Senha123');
    auth.pending = Completer<void>();
    await tester.tap(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(auth.calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    auth.pending!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('cadastro exige confirmação igual à senha', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthPage(auth: FakeAuth())));
    await tester.tap(find.text('Ainda não tem conta? Cadastre-se'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'viajante@teste.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Senha123');
    await tester.enterText(find.byType(TextFormField).at(2), 'OutraSenha');
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
  });
}
