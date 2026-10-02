import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'dart:async'; // 3.1 Importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Fixed constructor name

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

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
    // Para obtener el tamaño de la pantalla
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
                    // 1.2 vincular animacion
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      // 1.3 verificar que inicio bien
                      if (_controller == null) return;
                      // Agrega el controlador al escenario/tablero
                      artboard.addController(_controller!);
                      // Vinculamos variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      // 3.5 Vincular numLook
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),

                // para email
                const SizedBox(height: 10),
                TextField(
                  //4.10
                  controller: _emailCtrl,
                  // 2.3 Asignar foco al campo de texto
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      // _isHandsUp!.change(false);
                    }
                    if (_isChecking == null) return;
                    _isChecking!.change(true);

                    // 3.6 Implementar numLook
                    // Ajustes de limites del 0 a 100
                    // 80 es la medida de calibracion
                    final look =
                        (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    // clamp es el rango (abrazadera)
                    _numLook?.value = look;

                    //3.7 Debounce
                    _typingDebounce?.cancel();
                    //Crear un nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  }, // Fixed syntax error here
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

                // contraseña
                const SizedBox(height: 10),
                TextField(
                  //4.10 ENlazar controler
                  controller: _passCril,
                  // 2.3 Asignar foco al campo de texto
                  focusNode: _passwordFocus,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      // _isChecking!.change(false);
                    }
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
                        // refrescar el icono
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
                SizedBox(height: 10),
                //4.12 Texto olcide la contraseña
                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot password?',
                    //Alinear el pasword
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                //4.13 Boton de login
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  child: Text('Login', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                    width: size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Dont't have an account?"),
                        TextButton(
                            onPressed: () {},
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: Colors.black,
                                //subrayado
                                decoration: TextDecoration.underline,
                                //negritas
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      ],
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //4.15 Liberar los controladores
    _emailCtrl.dispose();
    _passCril.dispose();
    // 2.4 Liberar espacio en memoria
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel(); //3.9 Elimina el timer
    super.dispose();
  }
}
