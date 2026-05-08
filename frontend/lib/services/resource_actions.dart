import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recurso_model.dart';
import '../screens/detalle_recurso_screen.dart';

bool isPdfUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  return path.endsWith('.pdf');
}

Future<void> openRecurso(BuildContext context, Recurso recurso) async {
  final url = recurso.fullUrl;
  final shouldUseNativePdfViewer =
      isPdfUrl(url) && (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS);

  if (shouldUseNativePdfViewer) {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (opened) return;
  }

  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetalleRecursoScreen(recurso: recurso),
    ),
  );
}
