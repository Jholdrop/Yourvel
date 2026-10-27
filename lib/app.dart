import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/auth_page.dart';
import 'features/travel/data/travel_repository.dart';
import 'features/travel/presentation/diary_page.dart';

class YourvelApp extends StatelessWidget {
  const YourvelApp({super.key, this.auth, this.database});
  final AuthRepository? auth;
  final FirebaseFirestore? database;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Yourvel',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF206453),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F5EF),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F5EF),
        centerTitle: false,
      ),
    ),
    home: auth == null
        ? const SetupPage()
        : StreamBuilder(
            stream: auth!.session,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Não foi possível restaurar a sessão. Reinicie o aplicativo.',
                    ),
                  ),
                );
              }
              final user = snapshot.data;
              return user == null
                  ? AuthPage(auth: auth!)
                  : SessionNavigator(
                      key: ValueKey(user.uid),
                      auth: auth!,
                      repository: TravelRepository(database!, user.uid),
                    );
            },
          ),
  );
}

class SessionNavigator extends StatefulWidget {
  const SessionNavigator({
    super.key,
    required this.auth,
    required this.repository,
  });
  final AuthRepository auth;
  final TravelRepository repository;
  @override
  State<SessionNavigator> createState() => _SessionNavigatorState();
}

class _SessionNavigatorState extends State<SessionNavigator> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
    onPopWithResult: (_) => _navigator.currentState?.maybePop(),
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) =>
            DiaryPage(auth: widget.auth, repository: widget.repository),
      ),
    ),
  );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.explore_outlined,
                size: 64,
                color: Color(0xFF206453),
              ),
              const SizedBox(height: 24),
              Text('Yourvel', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Guarde os lugares. Reviva as histórias.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              const Text(
                'Configure o Firebase para começar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Android, coloque google-services.json em android/app e execute novamente o aplicativo. Para usar uma configuração explícita, siga o README e execute com --dart-define-from-file=config/firebase.json.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
