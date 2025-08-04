import 'package:flutter/material.dart';

class AjouterDevoirModal extends StatefulWidget {
  @override
  _AjouterDevoirModalState createState() => _AjouterDevoirModalState();
}

class _AjouterDevoirModalState extends State<AjouterDevoirModal> {
  final _formKey = GlobalKey<FormState>();
  String titre = '';
  String dateLimite = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouveau devoir"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Titre du devoir"),
              onSaved: (val) => titre = val ?? '',
              validator: (val) => val!.isEmpty ? "Titre requis" : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Date limite (ex: 2025-07-10)"),
              onSaved: (val) => dateLimite = val ?? '',
              validator: (val) => val!.isEmpty ? "Date requise" : null,
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
                'dateLimite': dateLimite,
              });
            }
          },
        ),
      ],
    );
  }
}
