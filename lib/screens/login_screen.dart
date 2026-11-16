import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear_animation/screens/register_screen.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onSuccessAnimationStart;
  final VoidCallback? onSuccessAnimationEnd;

  const LoginScreen({
    super.key,
    this.onSuccessAnimationStart,
    this.onSuccessAnimationEnd,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _emailCtrl = TextEditingController();
  final _passCril = TextEditingController();

  String? emailError;
  String? passError;

  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return re.hasMatch(pass);
  }

  Future<void> _onLogin() async {
    if (_isLoading) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCril.text;

    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    setState(() {
      emailError = eError;
      passError = pError;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    setState(() => _isLoading = true);
    widget.onSuccessAnimationStart?.call();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      _trigSuccess?.fire();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Inicio de sesión exitoso'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1600));
      widget.onSuccessAnimationEnd?.call();
    } on FirebaseAuthException catch (e) {
      widget.onSuccessAnimationEnd?.call();
      if (!mounted) return;

      _trigFail?.fire();

      String mensajeError = 'Error al iniciar sesión';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mensajeError = 'Correo o contraseña incorrectos';
      } else if (e.code == 'invalid-email') {
        mensajeError = 'Formato de correo inválido';
      } else if (e.code == 'too-many-requests') {
        mensajeError = 'Demasiados intentos. Intenta más tarde';
      }

      setState(() {
        passError = mensajeError;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $mensajeError'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      widget.onSuccessAnimationEnd?.call();
      if (!mounted) return;
      _trigFail?.fire();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onForgotPassword() async {
    final sentEmail = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailCtrl.text.trim(),
      ),
    );

    if (sentEmail == null || !mounted) return;

    _trigSuccess?.fire();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📩 Correo de recuperación enviado a $sentEmail'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    if (_isChecking == null) return;
                    _isChecking!.change(true);

                    final look =
                        (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    _numLook?.value = look;

                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passCril,
                  focusNode: _passwordFocus,
                  onChanged: (value) {
                    if (_isHandsUp == null) return;
                    _isHandsUp!.change(true);
                  },
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: Colors.pinkAccent,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    TextButton(
                      onPressed: _onForgotPassword,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onLogin,
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
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _emailCtrl.dispose();
    _passCril.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _resetCtrl;
  String? _dialogError;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _resetCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _resetCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _sendResetEmail() async {
    if (_isSending) return;

    final targetEmail = _resetCtrl.text.trim();
    if (!_isValidEmail(targetEmail)) {
      setState(() {
        _dialogError = 'Ingresa un correo válido';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _dialogError = null;
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
      if (!mounted) return;
      Navigator.of(context).pop(targetEmail);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errMsg = 'No se pudo enviar el correo';
      if (e.code == 'user-not-found') {
        errMsg = 'No existe una cuenta con ese correo';
      } else if (e.code == 'invalid-email') {
        errMsg = 'Formato de correo inválido';
      } else if (e.code == 'too-many-requests') {
        errMsg = 'Demasiados intentos, espera un momento';
      }
      setState(() {
        _dialogError = errMsg;
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dialogError = 'Ocurrió un error inesperado';
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Recuperar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _resetCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSending,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              errorText: _dialogError,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSending ? null : _sendResetEmail,
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Enviar enlace'),
        ),
      ],
    );
  }
}
