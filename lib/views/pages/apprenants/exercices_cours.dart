import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/passer_exercice.dart';

class ExercicesCoursPage extends StatefulWidget {
  final String coursId;

  const ExercicesCoursPage({super.key, required this.coursId});

  @override
  State<ExercicesCoursPage> createState() => _ExercicesCoursPageState();
}

class _ExercicesCoursPageState extends State<ExercicesCoursPage> {

  List exercices = [];
  List exercicesFiltres = [];

  // FIX: typage explicite String pour éviter List<DropdownMenuItem<Object>>
  List<String> modules = [];
  List<String> lecons = [];

  String? moduleSelectionne;
  String? leconSelectionnee;
  int? difficulte;
  String recherche = "";

  bool loading = true;

  final Color primaryColor = const Color(0xFF2884A0);
  final Color accentColor = const Color(0xFFFF7F77);

  @override
  void initState() {
    super.initState();
    fetchExercices();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchExercices() async {
    final token = await getToken();
    try {
      final res = await http.get(
        Uri.parse("https://yekiapp.pythonanywhere.com/api/cours/${widget.coursId}/exercices/"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Token $token",
        },
      );
      if (res.statusCode == 200) {
        exercices = jsonDecode(res.body);
        exercicesFiltres = exercices;

        // FIX: cast explicite en String
        modules = exercices.map((e) => e["module"].toString()).toSet().toList();
        lecons = exercices.map((e) => e["lecon"].toString()).toSet().toList();

        setState(() { loading = false; });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void filtrer() {
    List temp = exercices;
    if (moduleSelectionne != null) {
      temp = temp.where((e) => e["module"] == moduleSelectionne).toList();
    }
    if (leconSelectionnee != null) {
      temp = temp.where((e) => e["lecon"] == leconSelectionnee).toList();
    }
    if (difficulte != null) {
      temp = temp.where((e) => e["etoiles"] == difficulte).toList();
    }
    if (recherche.isNotEmpty) {
      temp = temp.where((e) =>
          e["titre"].toLowerCase().contains(recherche.toLowerCase())).toList();
    }
    setState(() { exercicesFiltres = temp; });
  }

  Widget _etoiles(int n) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < n ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Exercices du cours",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 20),
          _barreRecherche(),
          const SizedBox(height: 20),
          _filtres(),
          const SizedBox(height: 20),
          ...exercicesFiltres.map((ex) => _buildExerciceCard(ex)),
          const SizedBox(height: 30),
          _ficheTDButton(),
        ],
      ),
    );
  }

  Widget _barreRecherche() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Rechercher un exercice...",
        prefixIcon: Icon(Icons.search, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (v) {
        recherche = v;
        filtrer();
      },
    );
  }

  Widget _filtres() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: moduleSelectionne,
                hint: const Text("Module"),
                items: modules
                    .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  moduleSelectionne = v;
                  filtrer();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: leconSelectionnee,
                hint: const Text("Leçon"),
                items: lecons
                    .map((l) => DropdownMenuItem<String>(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  leconSelectionnee = v;
                  filtrer();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: difficulte,
          hint: const Text("Difficulté"),
          items: [1, 2, 3, 4, 5]
              .map((d) => DropdownMenuItem<int>(
                    value: d,
                    child: Row(children: [_etoiles(d)]),
                  ))
              .toList(),
          onChanged: (v) {
            difficulte = v;
            filtrer();
          },
        ),
      ],
    );
  }

  Widget _buildExerciceCard(Map ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.assignment, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex["titre"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                _etoiles(ex["etoiles"] ?? 0),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PasserExercicePage(exerciceId: ex["id"]),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Traiter"),
          ),
        ],
      ),
    );
  }

  Widget _ficheTDButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text("Générer la fiche TD"),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        Map niveaux = {};
        for (var ex in exercices) {
          int etoile = ex["etoiles"] ?? 1;
          if (!niveaux.containsKey(etoile)) niveaux[etoile] = [];
          niveaux[etoile].add(ex);
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Fiche TD"),
            content: SizedBox(
              width: 400,
              height: 400,
              child: ListView(
                children: niveaux.entries.map((e) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Difficulté ${e.key}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...e.value.map<Widget>(
                        (ex) => ListTile(title: Text(ex["titre"])),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}