import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/formaciones_screen.dart';
import '../screens/actividades_screen.dart';
import '../screens/dinamicas_screen.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<_DashboardItem> allItems = [
    _DashboardItem('Formaciones', Icons.school, Colors.blueAccent, FormacionesScreen()),
    _DashboardItem('Actividades', Icons.sports, Colors.green, ActividadesScreen()),
    _DashboardItem('Dinámicas', Icons.group, Colors.orangeAccent, DinamicasScreen()),
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = allItems
        .where((item) => item.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Buscar recursos...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (query) {
            setState(() => searchQuery = query);
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimationLimiter(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3 / 2,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final box = Hive.box('favoritos');
              final isFavorito = box.get(item.title, defaultValue: false);

              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 400),
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.screen),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black26,
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFavorito ? Icons.favorite : Icons.favorite_border,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      box.put(item.title, !isFavorito);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                              Icon(item.icon, size: 48, color: Colors.white),
                              const SizedBox(height: 12),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  _DashboardItem(this.title, this.icon, this.color, this.screen);
}
