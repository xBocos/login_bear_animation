import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:login_bear_animation/firebase_options.dart';
import 'package:login_bear_animation/screens/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<FirebaseApp> _firebaseInit;

  @override
  void initState() {
    super.initState();
    _firebaseInit = _inicializarFirebase();
  }

  Future<FirebaseApp> _inicializarFirebase() async {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('==================================================');
    debugPrint('✅ Firebase inicializado con éxito: ${app.name}');
    debugPrint('✅ FirebaseAuth listo: ${FirebaseAuth.instance.app.name}');
    debugPrint('==================================================');

    return app;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<FirebaseApp>(
        future: _firebaseInit,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Conectando con Firebase...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error al conectar con Firebase:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }

          return const _FirebaseReadyWrapper(
            child: AuthGate(),
          );
        },
      ),
    );
  }
}

class _FirebaseReadyWrapper extends StatefulWidget {
  final Widget child;
  const _FirebaseReadyWrapper({required this.child});

  @override
  State<_FirebaseReadyWrapper> createState() => _FirebaseReadyWrapperState();
}

class _FirebaseReadyWrapperState extends State<_FirebaseReadyWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🟢 Conexión exitosa con Firebase Auth'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
