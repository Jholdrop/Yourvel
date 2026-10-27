import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'features/auth/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var ready = false;
  const emulator = bool.fromEnvironment('USE_EMULATORS');
  try {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    if (apiKey.isNotEmpty || emulator) {
      await Firebase.initializeApp(
        options: emulator
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
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (emulator) {
        const host = String.fromEnvironment(
          'EMULATOR_HOST',
          defaultValue: '127.0.0.1',
        );
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);
        FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      }
      ready = true;
    }
  } catch (_) {
    // Não expor configuração ou detalhes internos na interface.
  }
  runApp(
    YourvelApp(
      auth: ready ? AuthRepository(FirebaseAuth.instance) : null,
      database: ready ? FirebaseFirestore.instance : null,
      storage: ready ? FirebaseStorage.instance : null,
      functions: ready ? FirebaseFunctions.instance : null,
    ),
  );
}
