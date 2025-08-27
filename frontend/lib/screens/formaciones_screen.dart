import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class FormacionesScreen extends StatefulWidget {
  const FormacionesScreen({super.key});

  @override
  _FormacionesScreenState createState() => _FormacionesScreenState();
}

class _FormacionesScreenState extends State<FormacionesScreen> {
  List<Recurso> recursos = [];
  bool loading = true;
  String searchQuery = "";

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
                hintText: "Buscar formaciones...",
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
