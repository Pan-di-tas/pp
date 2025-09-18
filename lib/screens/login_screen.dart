import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;

  // Controlador de Rive
  StateMachineController? controller;
  SMIBool? isChecking;
  SMIBool? isHandsUp;
  SMITrigger? trigSuccess; // deben ser SMITrigger
  SMITrigger? trigFail;

  @override
  Widget build(BuildContext context) {
    final Size tamano = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: tamano.width,
                height: 200,
                child: RiveAnimation.asset(
                  "assets/animated_login_character.riv",
                  stateMachines: const ["Login Machine"],
                  onInit: (artboard) {
                    controller = StateMachineController.fromArtboard(
                      artboard,
                      "Login Machine",
                    );
                    if (controller == null) return;
                    artboard.addController(controller!);

                    // Buscar los inputs
                    isChecking =
                        controller!.findInput<bool>("isChecking") as SMIBool?;
                    isHandsUp =
                        controller!.findInput<bool>("isHandsUp") as SMIBool?;
                    trigSuccess =
                        controller!.findInput<bool>("trigSuccess")
                            as SMITrigger?;
                    trigFail =
                        controller!.findInput<bool>("trigFail") as SMITrigger?;
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  // Baja las manos si escribe en email
                  if (isHandsUp != null) {
                    isHandsUp!.value = false;
                  }
                  // Activa modo chismoso
                  if (isChecking != null) {
                    isChecking!.value = true;
                  }
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.mail),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  // Apaga modo chismoso
                  if (isChecking != null) {
                    isChecking!.value = false;
                  }
                  // Levanta las manos si escribe en password
                  if (isHandsUp != null) {
                    isHandsUp!.value = true;
                  }
                },
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: tamano.width,
                child: const Text(
                  "¿Olvidaste tu contraseña?",
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 10),
              MaterialButton(
                minWidth: tamano.width,
                height: 50,
                color: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: () {
                  // Aquí podrías validar datos y disparar triggers
                  bool loginOk = true; // ejemplo
                  if (loginOk) {
                    trigSuccess?.fire();
                  } else {
                    trigFail?.fire();
                  }
                },
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: tamano.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account?"),
                    TextButton(onPressed: () {}, child: const Text("Register")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
