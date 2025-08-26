import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import 'detalle_recurso_screen.dart';

class DinamicasScreen extends StatefulWidget {
  const DinamicasScreen({super.key});

  @override
  State<DinamicasScreen> createState() => _DinamicasScreenState();
}

class _DinamicasScreenState extends State<DinamicasScreen> {
  String? selectedTema;
  String? selectedGrupo;
  List<Recurso> recursos = [];
  bool loading = true;

  final temas = ["Presentación", "Confianza", "Cooperación", "Animación"];
  final grupos = ["Pequeños", "Medianos", "Mayores"];

  @override
  void initState() {
    super.initState();
    fetchRecursos();
  }

  Future<void> fetchRecursos() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getRecursos(
        tipo: "dinamica",
        tema: selectedTema,
        grupo: selectedGrupo,
        page: 1,
        limit: 50,
      );
      setState(() {
        recursos = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void shareRecurso(Recurso recurso) {
    final message = "Mira esta dinámica: ${recurso.titulo}\n${recurso.fullUrl}";
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dinámicas")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<String>(
                  hint: const Text("Tema"),
                  value: selectedTema,
                  items: temas
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedTema = v);
                    fetchRecursos();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  hint: const Text("Grupo"),
                  value: selectedGrupo,
                  items: grupos
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedGrupo = v);
                    fetchRecursos();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : recursos.isEmpty
                    ? const Center(child: Text("No hay recursos disponibles"))
                    : ListView.builder(
                        itemCount: recursos.length,
                        itemBuilder: (context, index) {
                          final recurso = recursos[index];
                          return ListTile(
                            title: Text(recurso.titulo),
                            subtitle: Text(
                              recurso.grupo ?? '',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () => shareRecurso(recurso),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetalleRecursoScreen(recurso: recurso),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
