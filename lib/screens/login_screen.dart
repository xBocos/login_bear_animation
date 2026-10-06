import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  // NUEVO: Variable de estado local para el checkbox "Remember me"
  bool _rememberMe = false;

  // 1.1 crear el cerebro de la animacion
  StateMachineController? _controller;
  // SMI: State Machine Input
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // 3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  // 3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //4.1 Controllers que manipulam lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCril = TextEditingController();

  //4.2 Errores para mostrarlo en UI
  String? emailError;
  String? passError;

  //4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return re.hasMatch(pass);
  }

  //4.4 Dar acción al botón
  void _onLogin() {
    //De lo que escribió el usuario, quitar espacios en blanco
    final email = _emailCtrl.text.trim();
    final pass = _passCril.text;

    //4.6 Evaluar los correos
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    //4.7 Avisar que hubo cmabios
    setState(() {
      emailError = eError;
      passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus(); //Quita el foco
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.9 Activar trihgers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  // 2.2 Listeners
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          // 3.4 Mirada neutra
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener(() {
      // manos arriba en el password
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
                    if (_isHandsUp != null) {}
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
                    if (_isChecking != null) {}
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

                // NUEVO: Fila que contiene el Checkbox de Remember Me y Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: Colors
                              .pinkAccent, // Combinando con tu botón de Login
                          onChanged: (bool? value) {
                            setState(() {
                              // Manejo de estado local de la UI
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
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
                  onPressed: _onLogin,
                  child: const Text('Login',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
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
    _emailCtrl.dispose();
    _passCril.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
