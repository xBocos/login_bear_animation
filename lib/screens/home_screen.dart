import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSigningOut = false;

  Future<void> _onSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      messenger.clearSnackBars();
      await FirebaseAuth.instance.signOut();

      // Devuelve a la ruta raíz (AuthGate -> LoginScreen limpio con Rive)
      navigator.popUntil((route) => route.isFirst);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('👋 Sesión cerrada correctamente'),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Error al cerrar sesión'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _isSigningOut ? null : _onSignOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.pinkAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Bienvenido!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sesión activa como:\n${user?.email ?? 'Usuario'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _isSigningOut ? null : _onSignOut,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isSigningOut ? 'Cerrando...' : 'Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
