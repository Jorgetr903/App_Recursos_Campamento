import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class DinamicasScreen extends StatefulWidget {
  const DinamicasScreen({super.key});

  @override
  State<DinamicasScreen> createState() => _DinamicasScreenState();
}

class _DinamicasScreenState extends State<DinamicasScreen> {
  String? selectedTema;
  String? selectedGrupo;
  String? selectedSort = "recent"; // por defecto
  String searchQuery = "";
  List<Recurso> recursos = [];
  bool loading = true;

  final temas = ["Presentación", "Confianza", "Cooperación", "Animación"];
  final grupos = ["Pequeños", "Medianos", "Mayores"];
  final sortOptions = {
    "recent": "Más recientes",
    "oldest": "Más antiguos",
    "alpha": "Alfabético",
  };

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
        q: searchQuery.isNotEmpty ? searchQuery : null,
        sort: selectedSort,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dinámicas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            mainNavKey.currentState?.setIndex(0);
          },
        ),
      ),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar dinámicas...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                setState(() => searchQuery = value);
                fetchRecursos();
              },
            ),
          ),
          // Filtros: tema, grupo y ordenación
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 15,
              runSpacing: 8,
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
                DropdownButton<String>(
                  value: selectedSort,
                  items: sortOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedSort = v);
                    fetchRecursos();
                  },
                ),
              ],
            ),
          ),
          // Lista de recursos
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ResourceScreen(recursos: recursos),
          ),
        ],
      ),
    );
  }
}
