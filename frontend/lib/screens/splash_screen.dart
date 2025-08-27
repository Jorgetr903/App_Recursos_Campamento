import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import 'dashboard_screen.dart'; // importa tus screens según necesidad

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Inicialización de Hive
    await Hive.initFlutter();
    await Hive.openBox('favoritos');

    // Fetch inicial de recursos (simulación)
    await fetchRecursos();

    // Navega a la pantalla principal cuando termina
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainNavigation(key: mainNavKey)),
    );
  }

  Future<void> fetchRecursos() async {
    // Aquí puedes llamar a tu API real
    await Future.delayed(const Duration(seconds: 2)); // simulación
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/fondo.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/logoCSP.png",
              height: 200,
            ),
          ),
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
