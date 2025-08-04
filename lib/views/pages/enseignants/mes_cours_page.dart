import 'package:flutter/material.dart';
import 'ajout_enseignant_page.dart';
import 'detail_cours_enseignant.dart';

enum TypeEnseignantCours {
  enseignant,
  principal,
  administrateur,
  administrateurGeneral,
}

class Cours {
  final String nom;
  final String parcours;
  final String niveau;
  final String matiereOuConcoursOuDepartement;
  final String? description;
  final int nbLecons;
  final int nbApprenants;
  final int nbEnseignants;
  final bool estAttribue;

  const Cours({
    required this.nom,
    required this.parcours,
    required this.niveau,
    required this.matiereOuConcoursOuDepartement,
    this.description,
    required this.nbLecons,
    required this.nbApprenants,
    required this.nbEnseignants,
    this.estAttribue = false,
  });
}

class MesCoursPage extends StatefulWidget {
  final TypeEnseignantCours typeEnseignant;

  const MesCoursPage({super.key, required this.typeEnseignant});

  @override
  State<MesCoursPage> createState() => _MesCoursPageState();
}

class _MesCoursPageState extends State<MesCoursPage> {
  late List<Cours> coursFiltres;
  String? niveauFiltre;
  String? parcoursFiltre;

  @override
  void initState() {
    super.initState();
    coursFiltres = _getCoursSelonRole(widget.typeEnseignant);
  }

  List<Cours> _getCoursSelonRole(TypeEnseignantCours role) {
    const tous = [
      Cours(
        nom: "Mathématiques Terminale",
        parcours: "Secondaire Francophone",
        niveau: "Terminale",
        matiereOuConcoursOuDepartement: "Mathématiques",
        nbLecons: 12,
        nbApprenants: 35,
        nbEnseignants: 2,
        description: "Cours de préparation aux concours mathématiques.",
        estAttribue: true,
      ),
      Cours(
        nom: "Physique MINES",
        parcours: "Prépas",
        niveau: "Concours MINES",
        matiereOuConcoursOuDepartement: "Physique MINES",
        nbLecons: 10,
        nbApprenants: 30,
        nbEnseignants: 3,
        description: "Préparation au concours MINES.",
        estAttribue: false,
      ),
      Cours(
        nom: "Analyse L2",
        parcours: "Supérieur",
        niveau: "L2",
        matiereOuConcoursOuDepartement: "Mathématiques",
        nbLecons: 14,
        nbApprenants: 25,
        nbEnseignants: 1,
        description: "Analyse réelle en L2.",
        estAttribue: true,
      ),
    ];

    if (role == TypeEnseignantCours.administrateurGeneral) return tous;

    if (role == TypeEnseignantCours.administrateur) {
      return tous.where((c) => c.parcours == "Prépas").toList();
    }

    return tous.where((c) => c.estAttribue).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coursAffiches = coursFiltres.where((cours) {
      final filtreNiveau = niveauFiltre == null || cours.niveau == niveauFiltre;
      final filtreParcours =
          parcoursFiltre == null || cours.parcours == parcoursFiltre;
      return filtreNiveau && filtreParcours;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Cours",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                niveauFiltre = null;
                parcoursFiltre = null;
              });
            },
          )
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            _buildFiltres(),
            Expanded(
              child: ListView.builder(
                itemCount: coursAffiches.length,
                itemBuilder: (context, index) {
                  final cours = coursAffiches[index];
                  return _buildCarteCours(cours);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltres() {
    final niveaux = coursFiltres.map((c) => c.niveau).toSet().toList();
    final parcours = coursFiltres.map((c) => c.parcours).toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          DropdownButton<String>(
            value: parcoursFiltre,
            hint: const Text("Filtrer par parcours"),
            items: parcours
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => parcoursFiltre = val),
          ),
          DropdownButton<String>(
            value: niveauFiltre,
            hint: const Text("Filtrer par niveau"),
            items: niveaux
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => niveauFiltre = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteCours(Cours cours) {
    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailCoursEnseignantPage(
                cours: {
                  'titre': cours.nom,
                  'niveau': cours.niveau,
                  'description': cours.description,
                  'matiere': cours.matiereOuConcoursOuDepartement,
                  'nbEnseignants': cours.nbEnseignants,
                  'nbApprenants': cours.nbApprenants,
                  'lecons': [],        // liste des leçons
                  'enseignants': [],   // liste des enseignants
                  'exercices': [],     // liste des exercices
                  'devoirs': [],       // liste des devoirs
                },
                estEnseignantPrincipal:
                    widget.typeEnseignant == TypeEnseignantCours.principal,
              ),
            ),
          );
        },
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cours.nom,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF03224C))),
                const SizedBox(height: 6),
                Text(cours.description ?? "Aucune description",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoIcon(
                        Icons.school, "Parcours : ${cours.parcours}"),
                    _buildInfoIcon(Icons.grade, "Niveau : ${cours.niveau}"),
                    _buildInfoIcon(Icons.category, _getLabelCours(cours)),
                    _buildInfoIcon(Icons.menu_book, "${cours.nbLecons} leçons"),
                    _buildInfoIcon(
                        Icons.people, "${cours.nbApprenants} apprenants"),
                    _buildInfoIcon(
                        Icons.person, "${cours.nbEnseignants} enseignants"),
                  ],
                ),
                const SizedBox(height: 10),
                if (cours.estAttribue)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("✅ Attribué",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                const SizedBox(height: 6),
                if (_peutAjouterEnseignant(widget.typeEnseignant))
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text("Ajouter un enseignant"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AjoutEnseignantPage(
                              roleUtilisateur: 'enseignant principal',
                              nomCours: cours.nom,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ) // ta carte du cours
        );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.teal.shade700),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  bool _peutAjouterEnseignant(TypeEnseignantCours type) {
    return type == TypeEnseignantCours.principal ||
        type == TypeEnseignantCours.administrateur ||
        type == TypeEnseignantCours.administrateurGeneral;
  }

  String _getLabelCours(Cours cours) {
    if (cours.parcours == "Prépas") {
      return "Concours : ${cours.matiereOuConcoursOuDepartement}";
    } else if (cours.parcours == "Supérieur") {
      return "Département : ${cours.matiereOuConcoursOuDepartement}";
    } else {
      return "Matière : ${cours.matiereOuConcoursOuDepartement}";
    }
  }
}
