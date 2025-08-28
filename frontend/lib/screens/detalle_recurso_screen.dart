import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/recurso_model.dart';

class DetalleRecursoScreen extends StatefulWidget {
  final Recurso recurso;
  const DetalleRecursoScreen({super.key, required this.recurso});

  @override
  State<DetalleRecursoScreen> createState() => _DetalleRecursoScreenState();
}

class _DetalleRecursoScreenState extends State<DetalleRecursoScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecurso();
  }

  Future<void> loadRecurso() async {
    // Solo PDFs, no audio ni video
    await Future.delayed(const Duration(milliseconds: 500)); // simula carga
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (widget.recurso.fullUrl.endsWith('.pdf')) {
      // Muestra el PDF directamente
      content = SfPdfViewer.network(
        widget.recurso.fullUrl,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      );
    } else {
      content = const Center(child: Text("Tipo de archivo no soportado"));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.recurso.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.recurso.descripcion != null &&
                widget.recurso.descripcion!.isNotEmpty)
              Text(widget.recurso.descripcion!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
