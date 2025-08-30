import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnseignantAdminPage extends StatefulWidget {
  final int parcoursId; // parcours affecté
  const EnseignantAdminPage({super.key, required this.parcoursId});

  @override
  State<EnseignantAdminPage> createState() => _EnseignantAdminPageState();
}

class _EnseignantAdminPageState extends State<EnseignantAdminPage> {
  List departements = [];
  List enseignantsCadres = [];
  int? selectedCadreId;
  TextEditingController departementController = TextEditingController();
  bool isCreating = false; // 🔹 état du bouton

  @override
  void initState() {
    super.initState();
    fetchDepartements();
    fetchEnseignantsCadres();
  }

  Future<void> fetchDepartements() async {
    final res = await http.get(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/parcours/${widget.parcoursId}/departements/"),
    );
    if (res.statusCode == 200) {
      setState(() {
        departements = json.decode(res.body);
      });
    } else {
      print("Erreur fetchDepartements: ${res.body}");
    }
  }

  Future<void> fetchEnseignantsCadres() async {
    final res = await http.get(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/enseignants_cadres/"),
    );
    if (res.statusCode == 200) {
      setState(() {
        enseignantsCadres = json.decode(res.body);
      });
    } else {
      print("Erreur fetchEnseignantsCadres: ${res.body}");
    }
  }

  Future<void> createDepartement() async {
    if (departementController.text.isEmpty || selectedCadreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Remplis tous les champs"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isCreating = true; // 🔹 bouton désactivé
    });

    final res = await http.post(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/departements/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nom": departementController.text,
        "parcours": widget.parcoursId,
        "enseignant_cadre": selectedCadreId
      }),
    );

    setState(() {
      isCreating = false; // 🔹 réactive le bouton
    });

    if (res.statusCode == 201) {
      departementController.clear();
      setState(() {
        selectedCadreId = null;
      });
      await fetchDepartements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Département créé avec succès"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print("Erreur: ${res.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la création: ${res.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateCadre(int departementId, int cadreId) async {
    final res = await http.patch(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/departements/$departementId/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"enseignant_cadre": cadreId}),
    );
    if (res.statusCode == 200) {
      fetchDepartements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("👨‍🏫 Enseignant Cadre changé avec succès"),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      print("Erreur updateCadre: ${res.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Départements"),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION CRÉATION
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "➕ Créer un Département",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: departementController,
                      decoration: InputDecoration(
                        labelText: "Nom du département",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedCadreId,
                      items: enseignantsCadres.map<DropdownMenuItem<int>>((e) {
                        return DropdownMenuItem<int>(
                          value: e["id"],
                          child: Text(e["name"]),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCadreId = val),
                      decoration: InputDecoration(
                        labelText: "Choisir un Enseignant Cadre",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isCreating ? null : createDepartement, // 🔹 bouton désactivé
                        label: Text(
                          isCreating ? "Création..." : "Créer",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // LISTE DES DÉPARTEMENTS
            const Text("📋 Liste des Départements",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...departements.map((d) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    d["nom"],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "👨‍🏫 Cadre: ${d["cadre"] ?? "Aucun"}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: DropdownButton<int>(
                    hint: const Text("Changer"),
                    underline: const SizedBox(),
                    items: enseignantsCadres.map<DropdownMenuItem<int>>((e) {
                      return DropdownMenuItem<int>(
                        value: e["id"],
                        child: Text(e["name"]),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        updateCadre(d["id"], val);
                      }
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
