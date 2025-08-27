import 'package:flutter/material.dart';
import '../models/recurso_model.dart';
import '../services/api_service.dart';
import '../widgets/recurso_card.dart';
import '../main.dart'; // para mainNavKey

class FormacionesScreen extends StatefulWidget {
  const FormacionesScreen({super.key});
  @override
  _FormacionesScreenState createState() => _FormacionesScreenState();
}

class _FormacionesScreenState extends State<FormacionesScreen> {
  List<Recurso> recursos = [];
  bool loading = true;
  String searchQuery = "";
  String selectedSort = "recent"; // solo "más recientes"

  @override
  void initState() {
    super.initState();
    fetchRecursos();
  }

  Future<void> fetchRecursos() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getRecursos(
        tipo: "formacion",
        q: searchQuery.isNotEmpty ? searchQuery : null,
        sort: selectedSort,
        page: 1,
        limit: 50,
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Formaciones"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            mainNavKey.currentState?.setIndex(0); // vuelve al Dashboard
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar formaciones...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onSubmitted: (val) {
                setState(() => searchQuery = val);
                fetchRecursos();
              },
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRecursos,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: recursos.length,
                itemBuilder: (_, i) => RecursoCard(recurso: recursos[i]),
              ),
            ),
    );
  }
}
