import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recurso_model.dart';
import '../providers/favoritos_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ResourceScreen extends StatelessWidget {
  final List<Recurso> recursos;

  const ResourceScreen({super.key, required this.recursos});

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
            trailing: IconButton(
              icon: Icon(
                esFavorito ? Icons.favorite : Icons.favorite_border,
                color: esFavorito ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                favoritosProvider.toggleFavorito(recurso);
              },
            ),
            onTap: () {
              // Abrir recurso según tipo (solo PDF implementado como ejemplo)
              if (recurso.archivoUrl.endsWith('.pdf')) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(url: recurso.fullUrl, titulo: recurso.titulo),
                  ),
                );
              }
              // Para otros tipos (mp3/mp4), aquí podrías añadir más lógica si lo necesitas
            },
          ),
        );
      },
    );
  }
}

/// Pantalla simple para ver PDFs
class PdfViewerScreen extends StatelessWidget {
  final String url;
  final String titulo;

  const PdfViewerScreen({super.key, required this.url, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SfPdfViewer.network(url),
    );
  }
}
