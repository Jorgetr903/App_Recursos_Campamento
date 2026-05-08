import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recurso_model.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/resource_screen.dart';
import '../main.dart';

class FormacionesScreen extends StatefulWidget {
  const FormacionesScreen({super.key});

  @override
  State<FormacionesScreen> createState() => _FormacionesScreenState();
}

class _FormacionesScreenState extends State<FormacionesScreen> {
  List<Recurso> recursos = [];
  bool loading = true;
  String searchQuery = "";
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    fetchRecursos();
  }

  Future<void> fetchRecursos() async {
    final requestId = ++_requestId;
    setState(() => loading = true);

    try {
      final data = await ApiService.getRecursos(
        tipo: "formacion",
        q: searchQuery.isNotEmpty ? searchQuery : null,
        page: 1,
        limit: 50,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() => recursos = data);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => loading = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    if (searchQuery == value) return;

    setState(() => searchQuery = value);
    fetchRecursos();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        mainNavKey.currentState?.setIndex(0);
        return false;
      },
      child: Scaffold(
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: DebouncedSearchField(
                hintText: "Buscar formaciones...",
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ResourceScreen(recursos: recursos),
            ),
          ],
        ),
      ),
    );
  }
}
