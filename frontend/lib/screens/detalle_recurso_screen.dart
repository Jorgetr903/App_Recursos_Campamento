import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../models/recurso_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class DetalleRecursoScreen extends StatefulWidget {
  final Recurso recurso;

  const DetalleRecursoScreen({super.key, required this.recurso});

  @override
  _DetalleRecursoScreenState createState() => _DetalleRecursoScreenState();
}

class _DetalleRecursoScreenState extends State<DetalleRecursoScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  String? localPdfPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecurso();
  }

  Future<void> loadRecurso() async {
    if (widget.recurso.archivoUrl.endsWith('.pdf')) {
      // Descargar PDF
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${widget.recurso.titulo}.pdf';
      final response = await http.get(Uri.parse(widget.recurso.fullUrl));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        localPdfPath = filePath;
        loading = false;
      });
    } else if (widget.recurso.archivoUrl.endsWith('.mp4')) {
      _videoController = VideoPlayerController.network(widget.recurso.fullUrl)
        ..initialize().then((_) {
          setState(() => loading = false);
          _videoController!.play();
        });
    } else if (widget.recurso.archivoUrl.endsWith('.mp3')) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setUrl(widget.recurso.fullUrl);
      setState(() => loading = false);
      _audioPlayer!.play();
    } else {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recurso.titulo)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (widget.recurso.descripcion != null && widget.recurso.descripcion!.isNotEmpty)
                    Text(widget.recurso.descripcion!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  if (localPdfPath != null)
                    Expanded(child: PDFView(filePath: localPdfPath!)),
                  if (_videoController != null)
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  if (_audioPlayer != null)
                    Column(
                      children: [
                        const Icon(Icons.audiotrack, size: 64),
                        ElevatedButton(
                          onPressed: () {
                            _audioPlayer!.playing ? _audioPlayer!.pause() : _audioPlayer!.play();
                            setState(() {});
                          },
                          child: Text(_audioPlayer!.playing ? "Pausar" : "Reproducir"),
                        ),
                      ],
                    ),
                  if (_videoController == null &&
                      _audioPlayer == null &&
                      localPdfPath == null)
                    const Text("Tipo de archivo no soportado"),
                ],
              ),
            ),
    );
  }
}
