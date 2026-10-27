import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'features/auth/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var ready = false;
  FirebaseApp? configuredApp;
  const emulator = bool.fromEnvironment('USE_EMULATORS');
  final nativeAndroid =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  try {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    if (apiKey.isNotEmpty || emulator || nativeAndroid) {
      configuredApp = await Firebase.initializeApp(
        name: emulator
            ? 'yourvel-emulators'
            : apiKey.isNotEmpty
            ? 'yourvel-configured'
            : null,
        options: !emulator && apiKey.isEmpty
            ? null
            : emulator
            ? const FirebaseOptions(
                apiKey: 'demo-yourvel-key',
                appId: '1:123456789:web:yourvel',
                messagingSenderId: '123456789',
                projectId: 'demo-yourvel',
                storageBucket: 'demo-yourvel.appspot.com',
                authDomain: 'demo-yourvel.firebaseapp.com',
              )
            : const FirebaseOptions(
                apiKey: apiKey,
                appId: String.fromEnvironment('FIREBASE_APP_ID'),
                messagingSenderId: String.fromEnvironment(
                  'FIREBASE_MESSAGING_SENDER_ID',
                ),
                projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
                storageBucket: String.fromEnvironment(
                  'FIREBASE_STORAGE_BUCKET',
                ),
                authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
              ),
      );
      final auth = FirebaseAuth.instanceFor(app: configuredApp);
      final database = FirebaseFirestore.instanceFor(app: configuredApp);
      database.settings = const Settings(persistenceEnabled: false);
      if (emulator) {
        const host = String.fromEnvironment(
          'EMULATOR_HOST',
          defaultValue: '127.0.0.1',
        );
        await auth.useAuthEmulator(host, 9099);
        database.useFirestoreEmulator(host, 8080);
      }
      ready = true;
    }
  } catch (error) {
    if (kDebugMode) {
      // Registrar apenas código/tipo, sem valores de configuração ou tokens.
      debugPrint(
        error is FirebaseException
            ? 'Inicialização Firebase: ${error.plugin}/${error.code}'
            : 'Inicialização Firebase: ${error.runtimeType}',
      );
    }
  }
  runApp(
    YourvelApp(
      auth: ready
          ? AuthRepository(FirebaseAuth.instanceFor(app: configuredApp!))
          : null,
      database: ready
          ? FirebaseFirestore.instanceFor(app: configuredApp!)
          : null,
    ),
  );
}
