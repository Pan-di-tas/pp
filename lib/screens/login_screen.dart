import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
// 3.1 Importar librería para Timer
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPassword = false; // Para controlar la visibilidad de la contraseña

  // Cerebro de la lógica de las animaciones
  StateMachineController? controller;
  // SMI: State Machine Input
  SMIBool? isChecking; // Activa el modo "chismoso"
  SMIBool? isHandsUp; // Se tapa los ojos
  SMITrigger? trigSuccess; // Se emociona
  SMITrigger? trigFail; // Se pone sad
  // 2.1 Variable para recorrido de la mirada
  SMINumber? numLook;

  // 1) FocusNode
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // 3.2 Timer para detener la mirada al dejar de teclear
  Timer? _typingDebounce;

  //4.1 Controllers
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 Errores para pintar en la UI
  String? emailError;
  String? passError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Método acción al botón
  void _onLogin() {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Recalcular errores
    final eError = isValidEmail(email) ? null : 'NO bro otra vez hazlo bien';
    final pError = isValidPassword(pass)
        ? null
        : 'Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 caracter especial';

    setState(() {
      emailError = eError;
      passError = pError;

      // 4.6 Cerrar el teclado y bajar las manos
      FocusScope.of(context).unfocus();
      _typingDebounce?.cancel(); // cancelar el timer si existe
      isChecking?.change(false);
      isHandsUp?.change(false);
      numLook?.value = 50.0; // mirada neutra

      // 4.7 Activar triggers
      if (eError == null && pError == null) {
        trigSuccess?.fire();
      } else {
        trigFail?.fire();
      }
    });
  }

  // 2) Listeners (Oyentes/Chismoso)
  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        // Manos abajo en email
        isHandsUp?.change(false);
        // 2.2 Mirada neutral al enfocar email
        numLook?.value = 50.0;
      }
    });
    passFocus.addListener(() {
      // Manos arriba en password
      isHandsUp?.change(passFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consulta el tamaño de la pantalla del dispositivo
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      // Evita nudge o cámaras frontales para móviles
      body: SafeArea(
        child: Padding(
          // Eje x/horizontal/derecha izquierda
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  "assets/animated_login_character.riv",
                  // Controla las animaciones, es decir, los que estan definidos
                  stateMachines: ["Login Machine"],
                  // Al iniciarse, permite usar despues las animaciones, es como un controlador
                  onInit: (artboard) {
                    controller = StateMachineController.fromArtboard(
                      artboard,
                      "Login Machine",
                    );
                    // Verificar que inició bien
                    if (controller == null) return;
                    artboard.addController(controller!);
                    isChecking = controller!.findSMI("isChecking");
                    isHandsUp = controller!.findSMI("isHandsUp");
                    trigSuccess = controller!.findSMI("trigSuccess");
                    trigFail = controller!.findSMI("trigFail");
                    // 2.3 Enlazar variable con la animación
                    numLook = controller!.findSMI("numLook");
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Campo de texto del email
              TextField(
                focusNode: emailFocus,
                controller: emailCtrl,
                onChanged: (value) {
                  // Implementando numLook y mirada chismosa
                  if (isChecking != null) {
                    isChecking!.change(true);

                    final look = (value.length / 80.0 * 100.0).clamp(
                      0.0,
                      100.0,
                    );
                    numLook?.value = look;

                    // 3.3 Debounce: Si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 2), () {
                      if (!mounted) return;
                      isChecking?.change(false);
                    });
                  }
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  errorText: emailError,
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.mail),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Campo de texto de password
              TextField(
                focusNode: passFocus,
                controller: passCtrl,
                onChanged: (value) {
                  // Al escribir password, levantar manos y apagar chismoso
                  if (isHandsUp != null) {
                    isHandsUp!.change(true);
                  }
                  if (isChecking != null) {
                    isChecking!.change(false);
                  }
                },
                obscureText: !_isPassword,
                decoration: InputDecoration(
                  errorText: passError,
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPassword = !_isPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width,
                child: const Text(
                  "Forgot your password?",
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 10),
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _onLogin,
                child: const Text(
                  "Login",
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
                      onPressed: () {},
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4) Liberación de recursos / Limpieza de focus
  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
