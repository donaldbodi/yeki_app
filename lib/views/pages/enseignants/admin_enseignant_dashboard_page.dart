import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../widgets/yeki_app_bar.dart';

class EnseignantAdminPage extends StatefulWidget {
  final int parcoursId;
  final String role;
  final String nomUser;

  const EnseignantAdminPage({
    super.key,
    required this.parcoursId,
    required this.role,
    required this.nomUser,
  });

  @override
  State<EnseignantAdminPage> createState() => _EnseignantAdminPageState();
}

class _EnseignantAdminPageState extends State<EnseignantAdminPage> {
  List departements = [];
  List enseignantsCadres = [];
  String? nomParcours;
  bool isLoadingParcours = true;

  int? selectedCadreId;
  bool isCreating = false;

  final bool isSubscribed = true;

  final TextEditingController departementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDepartements();
    fetchParcours();
    fetchEnseignantsCadres();
  }

  /* ===================== API ===================== */
  Future<void> fetchParcours() async {
  final res = await http.get(
    Uri.parse(
      "https://yekiapp.pythonanywhere.com/api/parcours/${widget.parcoursId}/",
    ),
  );

  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    setState(() {
      nomParcours = data["nom"];
      isLoadingParcours = false;
    });
  } else {
    isLoadingParcours = false;
  }
}

  Future<void> fetchDepartements() async {
    final res = await http.get(
      Uri.parse(
        "https://yekiapp.pythonanywhere.com/api/parcours/${widget.parcoursId}/departements/",
      ),
    );

    if (res.statusCode == 200) {
      setState(() {
        departements = json.decode(res.body);
      });
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
    }
  }

  Future<void> createDepartement() async {
    if (departementController.text.isEmpty || selectedCadreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Tous les champs sont requis"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isCreating = true);

    final res = await http.post(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/departements/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nom": departementController.text,
        "parcours": widget.parcoursId,
        "enseignant_cadre": selectedCadreId,
      }),
    );

    setState(() => isCreating = false);

    if (res.statusCode == 201) {
      departementController.clear();
      selectedCadreId = null;

      await fetchDepartements();
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Département créé avec succès"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur : ${res.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateCadre(int departementId, int cadreId) async {
    final res = await http.patch(
      Uri.parse(
        "https://yekiapp.pythonanywhere.com/api/departements/$departementId/",
      ),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"enseignant_cadre": cadreId}),
    );

    if (res.statusCode == 200) {
      fetchDepartements();
    }
  }

  /* ===================== MODAL ===================== */

  void openCreateDepartementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                "➕ Nouveau Département",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: departementController,
                decoration: InputDecoration(
                  labelText: "Nom du département",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: selectedCadreId,
                items: enseignantsCadres.map<DropdownMenuItem<int>>((e) {
                  return DropdownMenuItem(
                    value: e["id"],
                    child: Text(e["user"]["username"].toString()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCadreId = val),
                decoration: InputDecoration(
                  labelText: "Enseignant cadre",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCreating ? null : createDepartement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Créer le département",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: isSubscribed,
        userRole: widget.role,
        username: widget.nomUser,
        avatarUrl: null,
        onNotifications: () {},
        onSettings: () {},
        onLogout: () {},
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text("Créer"),
        onPressed: openCreateDepartementModal,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
  isLoadingParcours
      ? "👋 Bienvenue Coordonnateur"
      : "👋 Bienvenue Coordonnateur du parcours $nomParcours",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.blue[900],
  ),
),

            const SizedBox(height: 6),
            const Text(
              "Voici la liste des départements que vous avez créés",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: departements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.apartment,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            "Aucun département créé",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: departements.length,
                      itemBuilder: (_, i) {
                        final d = departements[i];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(
                              d["nom"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "👨‍🏫 Cadre : ${d["cadre"]["user"]["username"] ?? "Non assigné"}",
                            ),
                            trailing: DropdownButton<int>(
                              hint: const Text("Changer"),
                              underline: const SizedBox(),
                              items: enseignantsCadres
                                  .map<DropdownMenuItem<int>>((e) {
                                return DropdownMenuItem(
                                  value: e["id"],
                                  child: Text(e["user"]["username"].toString()),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
