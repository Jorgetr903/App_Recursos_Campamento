import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Resource {
  final String id;
  final String title;
  final String subtitle;

  Resource({required this.id, required this.title, required this.subtitle});
}

class ResourceScreen extends StatefulWidget {
  final String title;
  final List<Resource> resources;

  const ResourceScreen({super.key, required this.title, required this.resources});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('favoritos');
    final filteredResources = widget.resources
        .where((r) => r.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
      ),
      body: AnimationLimiter(
        child: ListView.builder(
          itemCount: filteredResources.length,
          itemBuilder: (context, index) {
            final res = filteredResources[index];
            final isFavorito = box.get(res.id, defaultValue: false);

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 50,
                child: FadeInAnimation(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(res.title),
                      subtitle: Text(res.subtitle),
                      trailing: IconButton(
                        icon: Icon(
                          isFavorito ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          if (isFavorito) {
                            box.delete(res.id);
                          } else {
                            box.put(res.id, true);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
