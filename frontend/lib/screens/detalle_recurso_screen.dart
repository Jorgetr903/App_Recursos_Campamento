import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/recurso_model.dart';

class DetalleRecursoScreen extends StatefulWidget {
  final Recurso recurso;
  const DetalleRecursoScreen({super.key, required this.recurso});

  @override
  State<DetalleRecursoScreen> createState() => _DetalleRecursoScreenState();
}

class _DetalleRecursoScreenState extends State<DetalleRecursoScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecurso();
  }

  Future<void> loadRecurso() async {
    if (widget.recurso.fullUrl.endsWith('.mp4')) {
      _videoController = VideoPlayerController.network(widget.recurso.fullUrl);
      await _videoController!.initialize();
      _videoController!.play();
    } else if (widget.recurso.fullUrl.endsWith('.mp3')) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setUrl(widget.recurso.fullUrl);
      _audioPlayer!.play();
    }
    setState(() => loading = false);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (widget.recurso.fullUrl.endsWith('.mp4') && _videoController != null) {
      content = AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else if (widget.recurso.fullUrl.endsWith('.mp3') && _audioPlayer != null) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
      );
    } else if (widget.recurso.fullUrl.endsWith('.pdf')) {
      // Aquí se muestra el PDF directamente
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
            if (widget.recurso.descripcion != null && widget.recurso.descripcion!.isNotEmpty)
              Text(widget.recurso.descripcion!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
