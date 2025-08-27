import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  int? selectedAnio;
  String? selectedMomento;
  String? selectedSort = "recent"; // default
  String searchQuery = "";
  List<Recurso> recursos = [];
  bool loading = true;

  final momentos = ["Mañana", "Tarde", "Velada", "Olimpiada"];
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
        tipo: "actividad",
        anio: selectedAnio,
        momento: selectedMomento,
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
      appBar: AppBar(title: const Text("Actividades")),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar actividades...",
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
          // Filtros de año, momento y ordenación
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
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
                const SizedBox(width: 16),
                DropdownButton<String>(
                  hint: const Text("Momento"),
                  value: selectedMomento,
                  items: momentos
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedMomento = v);
                    fetchRecursos();
                  },
                ),
                const SizedBox(width: 16),
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
