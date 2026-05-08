import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/recurso_model.dart';
import '../providers/favoritos_provider.dart';
import '../services/download_service.dart';
import '../services/resource_actions.dart';
import '../web_utils_stub.dart'
    if (dart.library.js_interop) '../web_utils.dart';

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

  Future<void> _downloadFile(Recurso recurso) async {
    final downloadName = _downloadFilename(recurso.titulo, recurso.fullUrl);

    if (kIsWeb) {
      downloadUrl(recurso.downloadUrl, downloadName);
      return;
    }

    await DownloadService.downloadFile(recurso.fullUrl, downloadName, null);
  }

  void _shareFile(String url) {
    Share.share(url);
  }

  String _downloadFilename(String filename, String url) {
    final trimmedName = filename.trim().isEmpty ? 'archivo' : filename.trim();
    final safeName = trimmedName
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final hasPdfExtension = safeName.toLowerCase().endsWith('.pdf');

    return isPdfUrl(url) && !hasPdfExtension ? '$safeName.pdf' : safeName;
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
          final isPdf = isPdfUrl(recurso.fullUrl);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: ListTile(
              leading: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
              ),
              title: Text(recurso.titulo),
              subtitle:
                  recurso.descripcion != null ? Text(recurso.descripcion!) : null,
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
                    onPressed: () => _downloadFile(recurso),
                  ),
                ],
              ),
              onTap: () => openRecurso(context, recurso),
            ),
          );
        }

        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
