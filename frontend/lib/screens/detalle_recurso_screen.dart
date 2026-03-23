import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/recurso_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DetalleRecursoScreen extends StatefulWidget {
  final Recurso recurso;
  const DetalleRecursoScreen({super.key, required this.recurso});

  @override
  State<DetalleRecursoScreen> createState() => _DetalleRecursoScreenState();
}

class _DetalleRecursoScreenState extends State<DetalleRecursoScreen> {
  bool _isPdf() => widget.recurso.fullUrl.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recurso.titulo)),
      body: _isPdf() ? _buildPdfViewer() : const Center(child: Text("Tipo de archivo no soportado")),
    );
  }

  Widget _buildPdfViewer() {
    if (kIsWeb) {
      final encodedUrl = Uri.encodeComponent(widget.recurso.fullUrl);
      final iframeSrc = 'pdf_viewer.html?file=$encodedUrl';
      // ignore: undefined_prefixed_name, avoid_web_libraries_in_flutter
      return HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (element) {
          // ignore: avoid_web_libraries_in_flutter
          final iframe = element as dynamic;
          iframe.src = iframeSrc;
          iframe.style.border = 'none';
          iframe.style.width = '100%';
          iframe.style.height = '100%';
        },
      );
    } else {
      return SfPdfViewer.network(widget.recurso.fullUrl);
    }
  }
}