import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../models/recurso_model.dart';
import '../services/download_service.dart';

class DetalleRecursoScreen extends StatefulWidget {
  final Recurso recurso;
  const DetalleRecursoScreen({required this.recurso, super.key});

  @override
  _DetalleRecursoScreenState createState() => _DetalleRecursoScreenState();
}

class _DetalleRecursoScreenState extends State<DetalleRecursoScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool loadingDownload = false;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.recurso.tipoArchivo == 'video') {
        _videoController = VideoPlayerController.network(widget.recurso.urlArchivo)
          ..initialize().then((_) { setState(() {}); });
      } else if (widget.recurso.tipoArchivo == 'audio') {
        _audioPlayer = AudioPlayer()..setUrl(widget.recurso.urlArchivo);
      }
    } catch (e) {
      print("Error al cargar archivo: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> downloadFile() async {
    setState(() => loadingDownload = true);
    final path = await DownloadService.downloadFile(
      widget.recurso.urlArchivo,
      widget.recurso.titulo.replaceAll(' ', '_') + '.' + widget.recurso.tipoArchivo,
      (p) => setState(() => progress = p),
    );
    setState(() => loadingDownload = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(path != null ? "Archivo descargado en $path" : "Error al descargar")),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    try {
      if (widget.recurso.tipoArchivo == 'pdf') {
        contenido = PDFView(filePath: widget.recurso.urlArchivo);
      } else if (widget.recurso.tipoArchivo == 'video') {
        if (_videoController!.value.isInitialized) {
          contenido = AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          );
        } else {
          contenido = Center(child: CircularProgressIndicator());
        }
      } else if (widget.recurso.tipoArchivo == 'audio') {
        contenido = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.recurso.titulo, style: TextStyle(fontSize: 20)),
            IconButton(icon: Icon(Icons.play_arrow), onPressed: () => _audioPlayer!.play()),
            IconButton(icon: Icon(Icons.pause), onPressed: () => _audioPlayer!.pause()),
          ],
        );
      } else {
        contenido = Center(child: Text("Archivo no soportado"));
      }
    } catch (e) {
      contenido = Center(child: Text("No se pudo abrir este archivo"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recurso.titulo),
        actions: [
          IconButton(icon: Icon(Icons.download), onPressed: downloadFile),
        ],
      ),
      body: Column(
        children: [
          if (loadingDownload)
            LinearProgressIndicator(value: progress),
          Expanded(child: contenido),
        ],
      ),
    );
  }
}
