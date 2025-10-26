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
  bool _isLoading = false; // Controla el estado de carga (spinner)

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

  // 👇 Añadimos un timer a nivel de clase (por fuera del build)
  Timer? _hideHandsTimer;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return re.hasMatch(pass);
  }

  // 🔹 Método acción al botón
  Future<void> _onLogin() async {
    // Evita múltiples clics
    if (_isLoading) return;

    // Quitar foco, bajar manos y detener checking
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    isChecking?.change(false);
    isHandsUp?.change(false);
    numLook?.value = 50.0; // mirada neutra

    // Pequeña espera para que la State Machine procese el cambio de foco
    await Future.microtask(() {});

    // Mostrar el spinner
    setState(() => _isLoading = true);

    // Simula un envío
    await Future.delayed(const Duration(seconds: 1));

    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Validaciones usando las expresiones regulares
    final eError = email.isEmpty ? 'El campo email está vacío' : (!isValidEmail(email) ? 'Email inválido' : null);
    final pError = pass.isEmpty ? 'El campo contraseña está vacío' : (!isValidPassword(pass) ? 'Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 caracter especial' : null);

    // Actualizar el estado con los errores detectados
    setState(() {
      emailError = eError;
      passError = pError;
    });

    // ✅ Disparar trigger en el primer tap (corregido)
    if (eError == null && pError == null) {
      trigSuccess?.fire(); // Éxito
    } else {
      trigFail?.fire(); // Falla
    }

    // Ocultar spinner después del proceso
    setState(() => _isLoading = false);
  }

  // 2) Listeners (Oyentes/Chismoso)
  @override
  void initState() {
    super.initState();

    // Escucha los cambios de foco en email
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        // Manos abajo en email
        isHandsUp?.change(false);
        // 2.2 Mirada neutral al enfocar email
        numLook?.value = 50.0;
      }
    });

    // Escucha los cambios de foco en password
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
                    controller = StateMachineController.fromArtboard(artboard, "Login Machine");
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

                    final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    numLook?.value = look;

                    // 3.3 Debounce: Si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 2), () {
                      if (!mounted) return;
                      isChecking?.change(false);
                    });
                  }

                  // 🔹 Validación dinámica (solo un mensaje)
                  setState(() {
                    if (value.isEmpty) {
                      emailError = 'El campo email está vacío';
                    } else if (!isValidEmail(value)) {
                      emailError = 'Email inválido';
                    } else {
                      emailError = null;
                    }
                  });
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  errorText: emailError,
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.mail),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              // Campo de texto de password
              TextField(
                focusNode: passFocus,
                controller: passCtrl,
                obscureText: !_isPassword,
                decoration: InputDecoration(
                  errorText: passError,
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_isPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPassword = !_isPassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  // ✅ Si el usuario empieza a escribir, el oso se tapa los ojos
                  isHandsUp?.change(true);

                  // 🕒 Reiniciamos el temporizador cada vez que escribe algo
                  _hideHandsTimer?.cancel();
                  _hideHandsTimer = Timer(const Duration(seconds: 1), () {
                    // ⬇️ Pasados 2 segundos sin escribir, baja las manos
                    isHandsUp?.change(false);
                  });

                  // 🔹 Validación dinámica (solo un mensaje)
                  setState(() {
                    if (value.isEmpty) {
                      passError = 'El campo contraseña está vacío';
                    } else if (!isValidPassword(value)) {
                      passError = 'Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 caracter especial';
                    } else {
                      passError = null;
                    }
                  });
                },
                onTap: () {
                  // 🚫 Quitamos la animación inmediata al enfocar
                  // (ya no se tapa los ojos automáticamente aquí)
                },
                onEditingComplete: () {
                  // 👇 Por si presiona Enter y termina de escribir
                  isHandsUp?.change(false);
                },
              ),
              const SizedBox(height: 10),

              // (Checklist visual eliminado según tu petición:
              // los errores ahora se muestran solo en el campo activo vía errorText)
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
              // Botón con spinner de carga
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(color: Colors.white)),
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
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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
    _hideHandsTimer?.cancel();
    super.dispose();
  }
}
