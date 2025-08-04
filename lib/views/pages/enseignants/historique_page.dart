import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoriqueCours {
  final String titre;
  final String parcours;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nbApprenants;
  final int nbLecons;
  final int nbDevoirs;
  final int nbExercices;
  final List<String> notifications;

  HistoriqueCours({
    required this.titre,
    required this.parcours,
    required this.dateDebut,
    required this.dateFin,
    required this.nbApprenants,
    required this.nbLecons,
    required this.nbDevoirs,
    required this.nbExercices,
    this.notifications = const [],
  });
}

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({Key? key}) : super(key: key);

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  DateTime? filtreDebut;
  DateTime? filtreFin;

  final List<HistoriqueCours> allHistorique = [
    HistoriqueCours(
      titre: "Mathématiques Terminale C",
      parcours: "Secondaire Francophone",
      dateDebut: DateTime(2024, 9, 1),
      dateFin: DateTime(2025, 6, 30),
      nbApprenants: 30,
      nbLecons: 12,
      nbDevoirs: 5,
      nbExercices: 8,
      notifications: ["Feedback positif du cours", "Nouveau devoir publié"],
    ),
    HistoriqueCours(
      titre: "Physique L2",
      parcours: "Supérieur – Génie Informatique",
      dateDebut: DateTime(2024, 10, 15),
      dateFin: DateTime(2025, 5, 20),
      nbApprenants: 25,
      nbLecons: 10,
      nbDevoirs: 4,
      nbExercices: 6,
      notifications: ["Cours archivé", "Plus de 80 % de réussite"],
    ),
    HistoriqueCours(
      titre: "Concours MINES",
      parcours: "Prépas",
      dateDebut: DateTime(2025, 1, 5),
      dateFin: DateTime(2025, 7, 10),
      nbApprenants: 20,
      nbLecons: 7,
      nbDevoirs: 3,
      nbExercices: 10,
      notifications: ["Concours publié", "Échéance approchante"],
    ),
  ];

  List<HistoriqueCours> get filtered =>
      allHistorique.where((c) {
        final startOk = filtreDebut == null || c.dateDebut.isAfter(filtreDebut!) || c.dateDebut.isAtSameMomentAs(filtreDebut!);
        final endOk   = filtreFin == null || c.dateFin.isBefore(filtreFin!) || c.dateFin.isAtSameMomentAs(filtreFin!);
        return startOk && endOk;
      }).toList();

  Future<void> _pickDate({required bool isStart}) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) filtreDebut = picked;
        else filtreFin = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy‑MM‑dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon historique"),
        backgroundColor: const Color(0xFF008080),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(filtreDebut != null ? "Depuis ${df.format(filtreDebut!)}" : "Depuis"),
                    onPressed: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(filtreFin != null ? "Jusqu’au ${df.format(filtreFin!)}" : "Jusqu’à"),
                    onPressed: () => _pickDate(isStart: false),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    filtreDebut = filtreFin = null;
                  }),
                  tooltip: "Réinitialiser filtres",
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final c = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.history, color: Colors.teal),
                    title: Text(
                      c.titre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c.parcours),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      _infoRow(Icons.date_range, "Période",
                          "${df.format(c.dateDebut)} → ${df.format(c.dateFin)}"),
                      _infoRow(Icons.people, "Apprenants", "${c.nbApprenants}"),
                      _infoRow(Icons.menu_book, "Leçons", "${c.nbLecons}"),
                      _infoRow(Icons.assignment, "Devoirs", "${c.nbDevoirs}"),
                      _infoRow(Icons.fitness_center, "Exercices", "${c.nbExercices}"),
                      if (c.notifications.isNotEmpty) ...[
                        const Divider(),
                        const Text("🔔 Notifications :", style: TextStyle(fontWeight: FontWeight.bold)),
                        ...c.notifications.map((n) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("• $n"),
                            )),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: développer la navigation vers le détail historique
                          },
                          child: const Text("Voir les détails"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(IconData ic, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ic, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(valeur),
        ],
      ),
    );
  }
}
