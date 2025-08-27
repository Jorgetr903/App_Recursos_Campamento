import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  int? selectedAnio;
  String? selectedMomento;
  String searchQuery = "";
  List<Recurso> recursos = [];
  bool loading = true;

  final momentos = ["Mañana", "Tarde", "Velada", "Olimpiada"];

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
        title: const Text("Actividades"),
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
          // Filtros con Wrap (evita overflow en pantallas pequeñas)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 16,
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
