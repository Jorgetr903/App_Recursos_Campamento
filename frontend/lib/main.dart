import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/formaciones_screen.dart';
import 'screens/actividades_screen.dart';
import 'screens/dinamicas_screen.dart';
import 'screens/favoritos_screen.dart';
import 'providers/favoritos_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('favoritos');

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
        primaryColor: Colors.blueAccent,
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent)
            .copyWith(secondary: Colors.orangeAccent),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16)),
      ),
      home: MainNavigation(key: mainNavKey),
    );
  }
}

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
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: setIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Formaciones"),
          BottomNavigationBarItem(icon: Icon(Icons.sports), label: "Actividades"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Dinámicas"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoritos"),
        ],
      ),
    );
  }
}
