import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/iconos.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<_DashboardItem> allItems = [
    _DashboardItem('Formaciones', Icons.school, const Color(0xFF2196F3), 1),
    _DashboardItem('Actividades', Icons.sports, const Color(0xFF4CAF50), 2),
    _DashboardItem('Dinámicas', iconoCruz, const Color(0xFFFFC107), 3),
    _DashboardItem('Kiosko', Icons.store, const Color(0xFF1A5FA8), 5),
    // Abre la página del generador de plannings (la sirve el backend y pide
    // la misma clave que la subida de recursos).
    _DashboardItem('Generador de plannings', Icons.description, const Color(0xFF7B1FA2), -1,
        ruta: '/planning.html'),
  ];

  Future<void> _abrirPagina(String ruta) async {
    final messenger = ScaffoldMessenger.of(context);
    final origen = Uri.parse(ApiService.baseUrl).origin;
    bool abierto = false;
    try {
      abierto = await launchUrl(
        Uri.parse('$origen$ruta'),
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      abierto = false;
    }
    if (!abierto) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la página')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true; // permite salir
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "CSP",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimationLimiter(
            child: ListView.builder(
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 400),
                  child: SlideAnimation(
                    verticalOffset: 50,
                    child: FadeInAnimation(
                      child: GestureDetector(
                        onTap: () {
                          final ruta = item.ruta;
                          if (ruta != null) {
                            _abrirPagina(ruta);
                          } else {
                            mainNavKey.currentState?.setIndex(item.index);
                          }
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: Colors.black26,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [item.color.withOpacity(0.7), item.color],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.icon, size: 60, color: Colors.white),
                                const SizedBox(height: 12),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final int index;
  final String? ruta; // si no es null, abre esa página del backend

  _DashboardItem(this.title, this.icon, this.color, this.index, {this.ruta});
}
