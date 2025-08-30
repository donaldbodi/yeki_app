import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminGeneralDashboard extends StatefulWidget {
  const AdminGeneralDashboard({super.key});

  @override
  State<AdminGeneralDashboard> createState() => _AdminGeneralDashboardState();
}

class _AdminGeneralDashboardState extends State<AdminGeneralDashboard> {
  List parcoursList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchParcours();
  }

  Future<void> fetchParcours() async {
    final response = await http.get(Uri.parse("https://yekiapp.pythonanywhere.com/api/parcours/"));
    if (response.statusCode == 200) {
      setState(() {
        parcoursList = json.decode(response.body);
        loading = false;
      });
    }
  }

  Future<void> createParcours(String nom) async {
    final response = await http.post(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/parcours/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"nom": nom}),
    );
    if (response.statusCode == 201) {
      fetchParcours();
    }
  }

  Future<void> assignAdmin(int parcoursId, int adminId) async {
    final response = await http.put(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/parcours/$parcoursId/assign-admin/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"admin_id": adminId}),
    );
    if (response.statusCode == 200) {
      fetchParcours();
    }
  }

  Future<Map<String, dynamic>> fetchStats(int adminId) async {
    final response = await http.get(Uri.parse("https://yekiapp.pythonanywhere.com/api/stats/enseignant-admin/$adminId/"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  void showCreateParcoursDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Créer un parcours"),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: "Nom du parcours"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              createParcours(_controller.text);
              Navigator.pop(ctx);
            },
            child: Text("Créer"),
          )
        ],
      ),
    );
  }

  void showAssignAdminDialog(int parcoursId) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Assigner un enseignant_admin"),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: "ID de l'enseignant_admin"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              assignAdmin(parcoursId, int.parse(_controller.text));
              Navigator.pop(ctx);
            },
            child: Text("Assigner"),
          )
        ],
      ),
    );
  }

  void showStatsDialog(int adminId) async {
    final stats = await fetchStats(adminId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Statistiques"),
        content: stats.isEmpty
            ? Text("Aucune statistique disponible")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Départements: ${stats['departements']}"),
                  Text("Cours: ${stats['cours']}"),
                  Text("Leçons: ${stats['lecons']}"),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Fermer"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard Admin Général"),
        backgroundColor: Colors.blue[900],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: parcoursList.length,
              itemBuilder: (ctx, i) {
                final parcours = parcoursList[i];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(parcours['nom']),
                    subtitle: Text("Admin: ${parcours['admin']?['name'] ?? 'Non assigné'}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.person_add),
                          onPressed: () => showAssignAdminDialog(parcours['id']),
                        ),
                        if (parcours['admin'] != null)
                          IconButton(
                            icon: Icon(Icons.bar_chart),
                            onPressed: () => showStatsDialog(parcours['admin']['id']),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateParcoursDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
