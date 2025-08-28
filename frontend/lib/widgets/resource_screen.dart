import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recurso_model.dart';
import '../providers/favoritos_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../screens/detalle_recurso_screen.dart';

class ResourceScreen extends StatelessWidget {
  final List<Recurso> recursos;

  const ResourceScreen({super.key, required this.recursos});

  Future<void> _downloadFile(String url, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$filename';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    // Puedes mostrar un Snackbar o diálogo indicando que se descargó
  }

  void _shareFile(String url) {
    Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();

    return ListView.builder(
      itemCount: recursos.length,
      itemBuilder: (context, index) {
        final recurso = recursos[index];
        final esFavorito = favoritosProvider.esFavorito(recurso);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(recurso.titulo),
            subtitle: recurso.descripcion != null ? Text(recurso.descripcion!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_border,
                    color: esFavorito ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => favoritosProvider.toggleFavorito(recurso),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareFile(recurso.fullUrl),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(recurso.fullUrl, recurso.titulo),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleRecursoScreen(recurso: recurso),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
