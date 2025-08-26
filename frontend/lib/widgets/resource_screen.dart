import 'package:flutter/material.dart';
import '../models/recurso_model.dart';
import '../widgets/recurso_card.dart';

class ResourceScreen extends StatelessWidget {
  final List<Recurso> recursos;

  const ResourceScreen({
    super.key,
    required this.recursos,
  });

  @override
  Widget build(BuildContext context) {
    if (recursos.isEmpty) {
      return const Center(child: Text("No hay recursos disponibles"));
    }

    return ListView.builder(
      itemCount: recursos.length,
      itemBuilder: (context, index) {
        return RecursoCard(recurso: recursos[index]);
      },
    );
  }
}
