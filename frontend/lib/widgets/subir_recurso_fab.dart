import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

/// Botón verde con "+" que abre el formulario de subida de recursos
/// (una página que sirve el backend) con el tipo ya elegido.
class SubirRecursoFab extends StatelessWidget {
  /// "formacion", "actividad" o "dinamica" (como lo espera el formulario)
  final String tipo;

  const SubirRecursoFab({super.key, required this.tipo});

  Future<void> _abrirFormulario(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final origen = Uri.parse(ApiService.baseUrl).origin;
    final uri = Uri.parse('$origen/upload.html').replace(
      queryParameters: {'tipo': tipo},
    );

    bool abierto = false;
    try {
      abierto = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      abierto = false;
    }

    if (!abierto) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el formulario de subida')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      tooltip: 'Subir recurso',
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      onPressed: () => _abrirFormulario(context),
      child: const Icon(Icons.add),
    );
  }
}