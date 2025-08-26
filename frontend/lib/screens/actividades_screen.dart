import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';
import 'detalle_recurso_screen.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  int? selectedAnio;
  String? selectedMomento;
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
    final message = "Mira esta actividad: ${recurso.titulo}\n${recurso.fullUrl}";
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Actividades")),
      body: Column(
        children: [
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
                            subtitle: Text(recurso.momento ?? ''),
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
