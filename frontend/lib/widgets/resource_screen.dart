import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recurso_model.dart';
import '../providers/favoritos_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../screens/detalle_recurso_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class ResourceScreen extends StatelessWidget {
  final List<Recurso> recursos;
  final ScrollController? controller;
  final bool loading;
  final bool hasMore;

  const ResourceScreen({
    super.key,
    required this.recursos,
    this.controller,
    this.loading = false,
    this.hasMore = false,
  });

  Future<void> _downloadFile(String url, String filename) async {
    if (kIsWeb) {
      await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: '_blank',
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$filename';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
  }

  void _shareFile(String url) {
    Share.share(url);
  }

  // 🔹 Función para abrir PDFs, recibe context
  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    if (kIsWeb) {
      await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el PDF")),
        );
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();

    if (recursos.isEmpty && !loading) {
      return const Center(child: Text("No hay recursos disponibles"));
    }

    return ListView.builder(
      controller: controller,
      itemCount: recursos.length + (hasMore || loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < recursos.length) {
          final recurso = recursos[index];
          final esFavorito = favoritosProvider.esFavorito(recurso);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: Icon(
                recurso.archivoUrl.toLowerCase().endsWith('.pdf')
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
              ),
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
              // 🔹 Aquí abrimos PDFs directamente en navegador / PWA
              onTap: () {
                if (recurso.archivoUrl.toLowerCase().endsWith('.pdf')) {
                  _openPdf(context, recurso.fullUrl);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleRecursoScreen(recurso: recurso),
                    ),
                  );
                }
              },
            ),
          );
        } else {
          // Loader al final de la lista
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}