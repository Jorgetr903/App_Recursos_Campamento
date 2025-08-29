import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/formaciones_screen.dart';
import 'screens/actividades_screen.dart';
import 'screens/dinamicas_screen.dart';
import 'screens/favoritos_screen.dart';
import 'providers/favoritos_provider.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => FavoritosProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recursos Monitores',
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50), // Verde principal
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Fondo claro
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
        ).copyWith(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
          background: const Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF212121)),
        ),
      ),
      home: const SplashWrapper(),
    );
  }
}

// ---------------- Splash Custom ----------------
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Hive.initFlutter();
    await Hive.openBox('favoritos');

    await Future.delayed(const Duration(seconds: 5)); // simula carga

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainNavigation(key: mainNavKey)),
    );
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
              "assets/fondo-min.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/logoCSP.png",
              height: 200,
            ),
          ),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- MainNavigation ----------------
final GlobalKey<_MainNavigationState> mainNavKey =
    GlobalKey<_MainNavigationState>();

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final screens = [
    DashboardScreen(),
    const FormacionesScreen(),
    const ActividadesScreen(),
    const DinamicasScreen(),
    const FavoritosScreen(),
  ];

  void setIndex(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: setIndex,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          const BottomNavigationBarItem(icon: Icon(Icons.school), label: "Formaciones"),
          const BottomNavigationBarItem(icon: Icon(Icons.sports), label: "Actividades"),
          BottomNavigationBarItem(icon: Icon(MdiIcons.cross), label: "Dinámicas"),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoritos"),
        ],
      ),
    );
  }
}
