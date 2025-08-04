import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AjouterLeconModal extends StatefulWidget {
  const AjouterLeconModal({Key? key}) : super(key: key);

  @override
  State<AjouterLeconModal> createState() => _AjouterLeconModalState();
}

class _AjouterLeconModalState extends State<AjouterLeconModal> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _resumeController = TextEditingController();
  PlatformFile? _fichier;

  Future<void> _pickWordFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fichier = result.files.first;
      });
    }
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      if (_fichier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un fichier Word')),
        );
        return;
      }

      Navigator.pop(context, {
        'titre': _titreController.text.trim(),
        'resume': _resumeController.text.trim(),
        'fichier': _fichier, // à traiter si besoin côté backend
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Ajouter une leçon"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: "Titre",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? "Champ requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resumeController,
                decoration: const InputDecoration(
                  labelText: "Résumé",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? "Champ requis" : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickWordFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Sélectionner un fichier Word"),
              ),
              if (_fichier != null) ...[
                const SizedBox(height: 8),
                Text("Fichier sélectionné : ${_fichier!.name}", style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => 
          Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton.icon(
          onPressed: _valider,
          icon: const Icon(Icons.check),
          label: const Text("Ajouter"),
        ),
      ],
    );
  }
}

