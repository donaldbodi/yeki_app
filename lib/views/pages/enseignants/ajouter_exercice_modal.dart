import 'package:flutter/material.dart';

class AjouterExerciceModal extends StatefulWidget {
  @override
  _AjouterExerciceModalState createState() => _AjouterExerciceModalState();
}

class _AjouterExerciceModalState extends State<AjouterExerciceModal> {
  final _formKey = GlobalKey<FormState>();
  String titre = '';
  int nbQuestions = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouvel exercice"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Titre de l'exercice"),
              onSaved: (val) => titre = val ?? '',
              validator: (val) => val!.isEmpty ? "Titre requis" : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Nombre de questions"),
              keyboardType: TextInputType.number,
              onSaved: (val) => nbQuestions = int.tryParse(val ?? '0') ?? 0,
              validator: (val) => val!.isEmpty ? "Nombre requis" : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Annuler"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text("Ajouter"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.of(context).pop({
                'titre': titre,
                'nbQuestions': nbQuestions,
              });
            }
          },
        ),
      ],
    );
  }
}
