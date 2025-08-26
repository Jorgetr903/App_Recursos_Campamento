import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/recurso_model.dart';
import '../screens/detalle_recurso_screen.dart';
import '../providers/favoritos_provider.dart';

class ResourceScreen extends StatelessWidget {
  final List<Recurso> recursos;

  const ResourceScreen({super.key, required this.recursos});

  void shareRecurso(Recurso recurso) {
    final message = "Mira este recurso: ${recurso.titulo}\n${recurso.fullUrl}";
    Share.share(message);
  }

  Future<void> downloadRecurso(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo descargar el archivo")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recursos.isEmpty) {
      return const Center(child: Text("No hay recursos disponibles"));
    }

    final favoritosProvider = Provider.of<FavoritosProvider>(context);

    return ListView.builder(
      itemCount: recursos.length,
      itemBuilder: (context, index) {
        final recurso = recursos[index];
        final isFavorito = favoritosProvider.isFavorito(recurso);

        return ListTile(
          title: Text(recurso.titulo),
          subtitle: Text(recurso.momento ?? recurso.tema ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isFavorito ? Icons.favorite : Icons.favorite_border),
                onPressed: () => favoritosProvider.toggleFavorito(recurso),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => shareRecurso(recurso),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => downloadRecurso(recurso.fullUrl, context),
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
        );
      },
    );
  }
}
