import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _emailError;
  String? _passError;
  String? _confirmError;

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  // Misma regla de seguridad que tu LoginScreen (mínimo 8 caracteres, mayúscula, minúscula, número y símbolo)
  bool _isValidPassword(String pass) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$')
        .hasMatch(pass);
  }

  Future<void> _onRegister() async {
    if (_isLoading) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    final eErr = _isValidEmail(email) ? null : 'Formato de correo no válido';
    final pErr = _isValidPassword(pass)
        ? null
        : 'Mínimo 8 caracteres, mayúscula, minúscula, número y símbolo';
    final cErr = (confirm == pass && confirm.isNotEmpty)
        ? null
        : 'Las contraseñas no coinciden';

    setState(() {
      _emailError = eErr;
      _passError = pErr;
      _confirmError = cErr;
    });

    if (eErr != null || pErr != null || cErr != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Usuario registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Cierra RegisterScreen y regresa a AuthGate, que muestra HomeScreen automáticamente
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String msg = 'Error al registrar usuario';
      if (e.code == 'email-already-in-use') {
        msg = 'Este correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        msg = 'El formato del correo es inválido';
      } else if (e.code == 'weak-password') {
        msg = 'La contraseña es demasiado débil';
      }

      setState(() => _emailError = msg);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $msg'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.person_add_alt_1,
              size: 72,
              color: Colors.pinkAccent,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                errorText: _emailError,
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                errorText: _passError,
                errorMaxLines: 2,
                hintText: 'Password (Ej. Nuevo2026!)',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                errorText: _confirmError,
                hintText: 'Confirmar Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            MaterialButton(
              minWidth: size.width,
              height: 50,
              color: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: _isLoading ? null : _onRegister,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Registrarse',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
