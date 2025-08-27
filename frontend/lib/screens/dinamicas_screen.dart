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
  int? selectedAnio;
  String? selectedGrupo;
  String searchQuery = "";
  List<Recurso> recursos = [];
  bool loading = true;

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
        anio: selectedAnio,
        grupo: selectedGrupo,
        q: searchQuery.isNotEmpty ? searchQuery : null,
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
                DropdownButton<int>(
                  hint: const Text("Año"),
                  value: selectedAnio,
                  items: [2022, 2023, 2024, 2025]
                      .map((a) => DropdownMenuItem(value: a, child: Text("$a")))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedAnio = v);
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
