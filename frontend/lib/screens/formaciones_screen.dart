import 'package:flutter/material.dart';
import '../models/recurso_model.dart';
import '../services/api_service.dart';
import '../widgets/recurso_card.dart';

class FormacionesScreen extends StatefulWidget {
  const FormacionesScreen({super.key});
  @override
  _FormacionesScreenState createState() => _FormacionesScreenState();
}

class _FormacionesScreenState extends State<FormacionesScreen> {
  List<Recurso> recursos = [];
  bool loading = true;
  String search = "";

  @override
  void initState() {
    super.initState();
    fetchRecursos();
  }

  Future<void> fetchRecursos() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getRecursos(tipo: "formacion");
      setState(() => recursos = data);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Recurso> filtered = recursos
        .where((r) => r.titulo.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Formaciones"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => search = val),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRecursos,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) => RecursoCard(recurso: filtered[i]),
              ),
            ),
    );
  }
}
